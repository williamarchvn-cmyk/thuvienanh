-- =====================================================================
-- THƯ VIỆN ẢNH — tạo CSDL, kho ảnh, quyền truy cập, đồng bộ tức thời
-- Cách chạy: Supabase Dashboard → SQL Editor → New query → dán toàn bộ → Run
-- Chạy lại nhiều lần vẫn an toàn (không xóa dữ liệu đã có).
-- =====================================================================

-- ---------- 1. BẢNG ----------
create table if not exists public.photos (
  id            uuid primary key,                       -- trình duyệt tự sinh, cũng là tên file
  full_path     text not null unique,                   -- full/{id}.webp
  thumb_path    text not null,                          -- thumb/{id}.webp
  width         int  not null check (width > 0),
  height        int  not null check (height > 0),
  size_bytes    int  not null default 0 check (size_bytes >= 0),
  original_name text not null default '',
  note          text not null default '',
  tags          text[] not null default '{}',
  source_url    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz                             -- dành cho thùng rác (Phase 2)
);

-- v1.1.1: thứ tự tự sắp xếp ở trang "Tất cả ảnh" (kéo-thả). Để trống = xếp theo ngày tải lên.
alter table public.photos add column if not exists position double precision;

create table if not exists public.albums (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (char_length(name) between 1 and 80),
  cover_photo_id uuid references public.photos(id) on delete set null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists public.album_photos (
  album_id  uuid not null references public.albums(id) on delete cascade,
  photo_id  uuid not null references public.photos(id) on delete cascade,
  position  double precision not null,                 -- số lớn = hiện trước
  added_at  timestamptz not null default now(),
  primary key (album_id, photo_id)
);

-- ---------- 2. INDEX ----------
create index if not exists photos_created_at_idx      on public.photos (created_at desc);
create index if not exists album_photos_album_pos_idx on public.album_photos (album_id, position desc);
create index if not exists album_photos_photo_idx     on public.album_photos (photo_id);
create index if not exists albums_cover_idx           on public.albums (cover_photo_id);

-- ---------- 3. TỰ CẬP NHẬT updated_at ----------
create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists photos_updated_at on public.photos;
create trigger photos_updated_at before update on public.photos
  for each row execute function public.set_updated_at();

drop trigger if exists albums_updated_at on public.albums;
create trigger albums_updated_at before update on public.albums
  for each row execute function public.set_updated_at();

-- ---------- 4. QUYỀN TRUY CẬP ----------
-- Từ 2026, Supabase KHÔNG tự mở bảng mới cho app → phải GRANT tường minh.
grant select, insert, update, delete on public.photos, public.albums, public.album_photos to anon, authenticated;

-- Bật RLS và cho phép tất cả (app không đăng nhập — đã chốt G1).
-- Muốn khóa sau này: chỉ cần sửa các policy dưới đây.
alter table public.photos       enable row level security;
alter table public.albums       enable row level security;
alter table public.album_photos enable row level security;

drop policy if exists "open_all" on public.photos;
create policy "open_all" on public.photos       for all to anon, authenticated using (true) with check (true);
drop policy if exists "open_all" on public.albums;
create policy "open_all" on public.albums       for all to anon, authenticated using (true) with check (true);
drop policy if exists "open_all" on public.album_photos;
create policy "open_all" on public.album_photos for all to anon, authenticated using (true) with check (true);

-- ---------- 5. ĐỒNG BỘ TỨC THỜI (Realtime) ----------
do $$
declare t text;
begin
  foreach t in array array['photos','albums','album_photos'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------- 6. KHO ẢNH (Storage) ----------
-- Bucket public, chỉ nhận WebP, tối đa 5 MB/file
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 5242880, array['image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/webp'];

drop policy if exists "photos_read"   on storage.objects;
drop policy if exists "photos_upload" on storage.objects;
drop policy if exists "photos_delete" on storage.objects;
create policy "photos_read"   on storage.objects for select to anon, authenticated using (bucket_id = 'photos');
create policy "photos_upload" on storage.objects for insert to anon, authenticated with check (bucket_id = 'photos');
create policy "photos_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'photos');
-- Không cho phép ghi đè file (update): sửa ảnh = ảnh mới.

-- ---------- 8. TỆP TÀI LIỆU (v1.3.0: PDF, Word, Excel, PowerPoint, TXT, ZIP, DWG…) ----------
create table if not exists public.files (
  id         uuid primary key,                         -- trình duyệt tự sinh, cũng là tên file trong kho
  path       text not null unique,                     -- docs/{id}.{đuôi}
  name       text not null check (char_length(name) between 1 and 255),   -- tên gốc, hiện cho người dùng
  ext        text not null default '',
  mime       text not null default 'application/octet-stream',
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists files_created_at_idx on public.files (created_at desc);

drop trigger if exists files_updated_at on public.files;
create trigger files_updated_at before update on public.files
  for each row execute function public.set_updated_at();

grant select, insert, update, delete on public.files to anon, authenticated;
alter table public.files enable row level security;
drop policy if exists "open_all" on public.files;
create policy "open_all" on public.files for all to anon, authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'files') then
    alter publication supabase_realtime add table public.files;
  end if;
end $$;

-- Kho "files": public, tối đa 50 MB/tệp (trần của gói Free), chỉ nhận định dạng tài liệu.
-- KHÔNG cho HTML/SVG/JS để kho không bị dùng làm trang web giả.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('files', 'files', true, 52428800, array[
  'application/pdf',
  'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/rtf', 'application/vnd.oasis.opendocument.text',
  'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/csv', 'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.oasis.opendocument.presentation',
  'text/plain', 'text/markdown',
  'application/zip', 'application/vnd.rar', 'application/x-7z-compressed',
  'application/octet-stream'   -- bản vẽ DWG/DXF/SKP: trình duyệt luôn tải về, không mở
])
on conflict (id) do update
  set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "files_read"   on storage.objects;
drop policy if exists "files_upload" on storage.objects;
drop policy if exists "files_delete" on storage.objects;
create policy "files_read"   on storage.objects for select to anon, authenticated using (bucket_id = 'files');
create policy "files_upload" on storage.objects for insert to anon, authenticated with check (bucket_id = 'files');
create policy "files_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'files');

-- ---------- 7. KIỂM TRA ----------
-- Chạy xong, câu dưới phải trả về 4 dòng: photos, albums, album_photos, files
select tablename from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public';
