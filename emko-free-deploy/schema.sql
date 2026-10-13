-- Supabase SQL Editor에서 실행합니다. 계정/비밀번호는 포함되지 않습니다.
begin;
create table if not exists public.portal_admins(user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.portal_state(id integer primary key check(id=1),docs jsonb not null default '[]',logo jsonb,revision bigint not null default 0);
create table if not exists public.portal_audit(id bigint generated always as identity primary key,at timestamptz not null default now(),actor uuid,ip text,action text not null,detail text not null);
insert into public.portal_state(id) values(1) on conflict do nothing;
alter table public.portal_admins enable row level security;
alter table public.portal_state enable row level security;
alter table public.portal_audit enable row level security;
revoke all on public.portal_admins,public.portal_state,public.portal_audit from anon,authenticated;
create or replace function public.portal_is_admin() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.portal_admins where user_id=auth.uid())$$;
revoke all on function public.portal_is_admin() from public;
grant execute on function public.portal_is_admin() to anon,authenticated,service_role;
create or replace function public.portal_get_state() returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
select jsonb_build_object('docs',docs,'logo',logo,'revision',revision) into result from public.portal_state where id=1;
if public.portal_is_admin() then result=result||jsonb_build_object('audits',coalesce((select jsonb_agg(jsonb_build_object('at',at,'ip',ip,'action',action,'detail',detail) order by id desc) from public.portal_audit),'[]'::jsonb));end if;
return result;
end $$;
revoke all on function public.portal_get_state() from public;
grant execute on function public.portal_get_state() to anon,authenticated;
create or replace function public.portal_save_state(p_key text,p_value jsonb,p_revision bigint,p_actor uuid,p_ip text,p_action text,p_detail text) returns jsonb language plpgsql security definer set search_path='' as $$
declare actual bigint;result jsonb;
begin
if not exists(select 1 from public.portal_admins where user_id=p_actor) then raise exception '관리자 권한이 없습니다.';end if;
select revision into actual from public.portal_state where id=1 for update;
if actual<>p_revision then raise exception '다른 변경이 먼저 저장되었습니다. 새로고침 후 다시 수정해주세요.';end if;
if p_key='docs' and jsonb_typeof(p_value)='array' then update public.portal_state set docs=p_value,revision=revision+1 where id=1;
elsif p_key='logo' then update public.portal_state set logo=p_value,revision=revision+1 where id=1;
else raise exception '지원하지 않는 데이터입니다.';end if;
insert into public.portal_audit(actor,ip,action,detail) values(p_actor,p_ip,left(p_action,100),left(p_detail,5000));
select jsonb_build_object('revision',revision,'audits',coalesce((select jsonb_agg(jsonb_build_object('at',at,'ip',ip,'action',action,'detail',detail) order by id desc) from public.portal_audit),'[]'::jsonb)) into result from public.portal_state where id=1;
return result;
end $$;
revoke all on function public.portal_save_state(text,jsonb,bigint,uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.portal_save_state(text,jsonb,bigint,uuid,text,text,text) to service_role;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('portal-files','portal-files',true,20971520,array['application/pdf','image/png','image/jpeg']) on conflict(id) do update set public=true,file_size_limit=20971520,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists portal_admin_upload on storage.objects;
create policy portal_admin_upload on storage.objects for insert to authenticated with check(bucket_id='portal-files' and public.portal_is_admin());
drop policy if exists portal_admin_file_read on storage.objects;
create policy portal_admin_file_read on storage.objects for select to authenticated using(bucket_id='portal-files' and public.portal_is_admin());
drop policy if exists portal_admin_file_delete on storage.objects;
create policy portal_admin_file_delete on storage.objects for delete to authenticated using(bucket_id='portal-files' and public.portal_is_admin());
commit;
-- 관리자 계정 생성 후 아래 별도 명령으로 UID를 등록하세요.
-- insert into public.portal_admins(user_id) values ('관리자 계정 UUID');
