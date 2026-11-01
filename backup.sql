


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."admin_stats"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 if not public.is_admin() then raise exception 'not admin'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   return jsonb_build_object(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'users',  coalesce(nullif(public.est_rows('auth.users'::regclass), 0), (select count(*) from auth.users)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           'decks',  coalesce(nullif(public.est_rows('public.decks'::regclass), 0), (select count(*) from public.decks)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               'cards',  coalesce(nullif(public.est_rows('public.cards'::regclass), 0), (select count(*) from public.cards)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   'shares', coalesce(nullif(public.est_rows('public.shares'::regclass), 0), (select count(*) from public.shares)));
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   end $$;


ALTER FUNCTION "public"."admin_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer DEFAULT 30, "p_seed" "text" DEFAULT ''::"text", "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "deck_id" "uuid", "front" "text", "back" "text", "state" "text", "step" integer, "ease" numeric, "ivl_days" numeric, "reps" integer, "lapses" integer, "due" timestamp with time zone, "last_review" timestamp with time zone, "first_seen" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              #variable_conflict use_column
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              declare v_uid uuid := auth.uid();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                if v_uid is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  if not exists (select 1 from public.decks d where d.id = p_deck and d.user_id = v_uid) then return; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        select c.id, c.deck_id, c.front::text, c.back::text, c.state::text, c.step::integer, c.ease::numeric,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   c.ivl_days::numeric, c.reps::integer, c.lapses::integer, c.due::timestamptz,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              c.last_review::timestamptz, c.first_seen::timestamptz
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      where c.deck_id = p_deck
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          order by c.created_at, c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              limit least(greatest(coalesce(p_limit, 30), 1), 100)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  offset least(greatest(coalesce(p_offset, 0), 0), 100000);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  end $$;


ALTER FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb" DEFAULT NULL::"jsonb", "p_folder" "uuid" DEFAULT NULL::"uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_uid uuid := auth.uid();
    v_name text := left(btrim(coalesce(p_name, '')), 120);
      v_payload jsonb;
        v_kind text;
          v_code text;
            v_try integer := 0;
              v_nf bigint; v_nd bigint; v_nc bigint;
              begin
                if v_uid is null then raise exception 'auth required'; end if;
                  if v_name = '' then raise exception 'bad name'; end if;
                    if (select count(*) from public.shares s where s.user_id = v_uid and s.created_at > now() - interval '1 hour') >= 30 then
                        raise exception 'rate limited';
                          end if;

                            -- [إضافة جديدة] تنظيف المشاركات التي مر عليها أكثر من 7 أيام
                              delete from public.shares where created_at < now() - interval '7 days';

                                if p_folder is null then
                                    if p_cards is null or jsonb_typeof(p_cards) <> 'array' then raise exception 'bad cards'; end if;
                                        if jsonb_array_length(p_cards) > 1000 then raise exception 'too large'; end if;
                                            select coalesce(jsonb_agg(jsonb_build_object('front', left(e.v ->> 'front', 2000), 'back', left(e.v ->> 'back', 4000)) order by e.ord), '[]'::jsonb)
                                                into v_payload
                                                    from jsonb_array_elements(p_cards) with ordinality as e(v, ord)
                                                        where jsonb_typeof(e.v) = 'object' and jsonb_typeof(e.v -> 'front') = 'string' and jsonb_typeof(e.v -> 'back') = 'string' and btrim(e.v ->> 'front') <> '' and btrim(e.v ->> 'back') <> '';
                                                            if jsonb_array_length(v_payload) = 0 then raise exception 'bad cards'; end if;
                                                                v_kind := 'deck';
                                                                  else
                                                                      if not exists (select 1 from public.folders f where f.id = p_folder and f.user_id = v_uid) then raise exception 'not found'; end if;
                                                                          with recursive t as (
                                                                                select f.id, f.parent_id, f.name, f.icon, f.color, f.created_at, 0 as depth from public.folders f where f.id = p_folder and f.user_id = v_uid
                                                                                      union all
                                                                                            select f.id, f.parent_id, f.name, f.icon, f.color, f.created_at, t.depth + 1 from public.folders f join t on f.parent_id = t.id where f.user_id = v_uid and t.depth < 30
                                                                                                ), o as (
                                                                                                      select t.*, (row_number() over (order by t.depth, t.created_at, t.id) - 1)::integer as idx from t
                                                                                                          ), dk as (
                                                                                                                select d.id, d.name, d.color, o.idx as fidx, (row_number() over (order by o.idx, d.created_at, d.id) - 1)::integer as didx
                                                                                                                      from public.decks d join o on o.id = d.folder_id where d.user_id = v_uid
                                                                                                                          )
                                                                                                                              select (select count(*) from o), (select count(*) from dk), (select count(*) from public.cards c join dk on dk.id = c.deck_id),
                                                                                                                                         jsonb_build_object(
                                                                                                                                                      'folders', (select coalesce(jsonb_agg(jsonb_build_object('name', o.name, 'icon', o.icon, 'color', o.color, 'parent', p.idx) order by o.idx), '[]'::jsonb) from o left join o p on p.id = o.parent_id),
                                                                                                                                                                   'decks', (select coalesce(jsonb_agg(jsonb_build_object('name', dk.name, 'color', dk.color, 'folder', dk.fidx,
                                                                                                                                                                                    'cards', (select coalesce(jsonb_agg(jsonb_build_object('front', c.front, 'back', c.back) order by c.created_at, c.id), '[]'::jsonb) from public.cards c where c.deck_id = dk.id))
                                                                                                                                                                                                     order by dk.didx), '[]'::jsonb) from dk))
                                                                                                                                                                                                         into v_nf, v_nd, v_nc, v_payload;
                                                                                                                                                                                                             if v_nf > 200 or v_nd > 200 or v_nc > 5000 then raise exception 'too large'; end if;
                                                                                                                                                                                                                 if v_nd = 0 or v_nc = 0 then raise exception 'bad data'; end if;
                                                                                                                                                                                                                     v_kind := 'folder';
                                                                                                                                                                                                                       end if;

                                                                                                                                                                                                                         loop
                                                                                                                                                                                                                             v_code := substr(md5(gen_random_uuid()::text), 1, 8);
                                                                                                                                                                                                                                 begin
                                                                                                                                                                                                                                       insert into public.shares (code, user_id, name, kind, cards) values (v_code, v_uid, v_name, v_kind, v_payload);
                                                                                                                                                                                                                                             exit;
                                                                                                                                                                                                                                                 exception when unique_violation then
                                                                                                                                                                                                                                                       v_try := v_try + 1;
                                                                                                                                                                                                                                                             if v_try > 5 then raise; end if;
                                                                                                                                                                                                                                                                 end;
                                                                                                                                                                                                                                                                   end loop;

                                                                                                                                                                                                                                                                     delete from public.shares s where s.user_id = v_uid and s.code in (select s2.code from public.shares s2 where s2.user_id = v_uid order by s2.created_at desc offset 100);
                                                                                                                                                                                                                                                                       return v_code;
                                                                                                                                                                                                                                                                       end $$;


ALTER FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb", "p_folder" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer DEFAULT 30, "p_new_limit" integer DEFAULT 20, "p_day" "date" DEFAULT NULL::"date", "p_exclude" "uuid"[] DEFAULT '{}'::"uuid"[]) RETURNS TABLE("id" "uuid", "deck_id" "uuid", "front" "text", "back" "text", "state" "text", "step" integer, "ease" numeric, "ivl_days" numeric, "reps" integer, "lapses" integer, "due" timestamp with time zone, "last_review" timestamp with time zone, "first_seen" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    #variable_conflict use_column
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    declare
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      v_uid uuid := auth.uid();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        v_now timestamptz := now();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          v_lim integer := least(greatest(coalesce(p_limit, 30), 1), 100);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_ex  uuid[] := array(select t.e from unnest(coalesce(p_exclude, '{}'::uuid[])) as t(e) where t.e is not null);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              v_day date := coalesce(p_day, (now() at time zone 'utc')::date);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                v_n integer := 0;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  v_new integer;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    if v_uid is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      if cardinality(v_ex) > 600 then raise exception 'too large'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        if not exists (select 1 from public.decks d where d.id = p_deck and d.user_id = v_uid) then return; end if;

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              select c.id, c.deck_id, c.front::text, c.back::text, c.state::text, c.step::integer, c.ease::numeric,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         c.ivl_days::numeric, c.reps::integer, c.lapses::integer, c.due::timestamptz,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    c.last_review::timestamptz, c.first_seen::timestamptz
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            where c.deck_id = p_deck and c.state <> 'new' and c.due <= v_now and not (c.id = any (v_ex))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                order by c.due, c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    limit v_lim;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      select count(*) into v_n from (
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          select 1 from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              where c.deck_id = p_deck and c.state <> 'new' and c.due <= v_now and not (c.id = any (v_ex))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  limit v_lim) q;

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    v_new := least(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        greatest(coalesce(p_new_limit, 0) - coalesce((select nc.n from public.new_counts nc
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          where nc.user_id = v_uid and nc.day = v_day), 0), 0),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              v_lim - v_n);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                if v_new > 0 then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          select c.id, c.deck_id, c.front::text, c.back::text, c.state::text, c.step::integer, c.ease::numeric,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       c.ivl_days::numeric, c.reps::integer, c.lapses::integer, c.due::timestamptz,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    c.last_review::timestamptz, c.first_seen::timestamptz
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                where c.deck_id = p_deck and c.state = 'new' and not (c.id = any (v_ex))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      order by c.created_at, c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            limit v_new;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              end $$;


ALTER FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer, "p_new_limit" integer, "p_day" "date", "p_exclude" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."est_rows"("p" "regclass") RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                select greatest(c.reltuples, 0)::bigint from pg_class c where c.oid = p
                                                                                                                                $$;


ALTER FUNCTION "public"."est_rows"("p" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."folder_tree"("p_user" "uuid", "p_root" "uuid") RETURNS TABLE("id" "uuid", "parent_id" "uuid", "name" "text", "icon" "text", "color" "text", "idx" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                  with recursive t as (
                                                                                                                                      select f.id, f.parent_id, f.name, f.icon, f.color, 0 as depth
                                                                                                                                            from public.folders f where f.id = p_root and f.user_id = p_user
                                                                                                                                                union all
                                                                                                                                                    select c.id, c.parent_id, c.name, c.icon, c.color, t.depth + 1
                                                                                                                                                          from public.folders c join t on c.parent_id = t.id
                                                                                                                                                                where c.user_id = p_user and t.depth < 20)
                                                                                                                                                                  select t.id, t.parent_id, t.name, t.icon, t.color,
                                                                                                                                                                           (row_number() over (order by t.depth, t.name, t.id))::int - 1
                                                                                                                                                                             from t
                                                                                                                                                                             $$;


ALTER FUNCTION "public"."folder_tree"("p_user" "uuid", "p_root" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_share"("p_code" "text") RETURNS TABLE("name" "text", "kind" "text", "cards" "jsonb")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    if auth.uid() is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          select s.name, s.kind, s.cards from public.shares s
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              where s.code = lower(btrim(coalesce(p_code, ''))) limit 1;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              end $$;


ALTER FUNCTION "public"."get_share"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."home_snapshot"("p_day" "date" DEFAULT NULL::"date") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
                                                                                                                                                                                                                                       declare
                                                                                                                                                                                                                                         v_uid uuid := auth.uid();
                                                                                                                                                                                                                                           v_now timestamptz := now();
                                                                                                                                                                                                                                             v_day date := coalesce(p_day, (now() at time zone 'utc')::date);
                                                                                                                                                                                                                                             begin
                                                                                                                                                                                                                                               if v_uid is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                 return jsonb_build_object(
                                                                                                                                                                                                                                                     'decks', coalesce((
                                                                                                                                                                                                                                                           select jsonb_agg(jsonb_build_object('id', d.id, 'name', d.name, 'color', d.color, 'folder_id', d.folder_id,
                                                                                                                                                                                                                                                                                                     'srs_enabled', d.srs_enabled, 'created_at', d.created_at)
                                                                                                                                                                                                                                                                                                                            order by d.created_at desc, d.id)
                                                                                                                                                                                                                                                                                                                                  from public.decks d where d.user_id = v_uid), '[]'::jsonb),
                                                                                                                                                                                                                                                                                                                                      'folders', coalesce((
                                                                                                                                                                                                                                                                                                                                            select jsonb_agg(jsonb_build_object('id', f.id, 'name', f.name, 'icon', f.icon, 'color', f.color, 'parent_id', f.parent_id)
                                                                                                                                                                                                                                                                                                                                                                   order by f.created_at, f.id)
                                                                                                                                                                                                                                                                                                                                                                         from public.folders f where f.user_id = v_uid), '[]'::jsonb),
                                                                                                                                                                                                                                                                                                                                                                             'counts', coalesce((
                                                                                                                                                                                                                                                                                                                                                                                   select jsonb_object_agg(d.id, jsonb_build_object(
                                                                                                                                                                                                                                                                                                                                                                                                  'total',    a.total,
                                                                                                                                                                                                                                                                                                                                                                                                                 'new',      a.n_new,
                                                                                                                                                                                                                                                                                                                                                                                                                                'due',      a.n_due,
                                                                                                                                                                                                                                                                                                                                                                                                                                               'ready',    a.n_due,
                                                                                                                                                                                                                                                                                                                                                                                                                                                              'next_due', u.ups[1],
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             'upc',      to_jsonb(u.ups)))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   from public.decks d
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         cross join lateral (select
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   (select count(*) from public.cards c where c.deck_id = d.id)                                                    as total,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             (select count(*) from public.cards c where c.deck_id = d.id and c.state = 'new')                                as n_new,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       (select count(*) from public.cards c where c.deck_id = d.id and c.state <> 'new' and c.due <= v_now)            as n_due
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ) a
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     cross join lateral (select array(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               select c.due from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         where c.deck_id = d.id and c.state <> 'new' and c.due > v_now
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   order by c.due limit 10) as ups
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ) u
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 where d.user_id = v_uid), '{}'::jsonb),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'settings', (select jsonb_build_object('max_interval', s.max_interval, 'new_per_day', s.new_per_day,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                'step_again', s.step_again, 'step_hard', s.step_hard,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           'step_good', s.step_good, 'step_easy', s.step_easy)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            from public.user_settings s where s.user_id = v_uid),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                'new_today', coalesce((select nc.n from public.new_counts nc where nc.user_id = v_uid and nc.day = v_day), 0)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  );
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  end $$;


ALTER FUNCTION "public"."home_snapshot"("p_day" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_new_counter"("p_day" "date" DEFAULT NULL::"date", "p_by" integer DEFAULT 1) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                 declare v uuid := auth.uid(); d date := coalesce(p_day, current_date); r int;
                                                                                                                                                                                                                                                                                                                                                                                 begin
                                                                                                                                                                                                                                                                                                                                                                                   if v is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                     if abs(d - current_date) > 2 then d := current_date; end if;
                                                                                                                                                                                                                                                                                                                                                                                       insert into public.daily_new_counters (user_id, day, count)
                                                                                                                                                                                                                                                                                                                                                                                         values (v, d, least(greatest(coalesce(p_by, 1), 1), 500))
                                                                                                                                                                                                                                                                                                                                                                                           on conflict (user_id, day)
                                                                                                                                                                                                                                                                                                                                                                                             do update set count = least(public.daily_new_counters.count + excluded.count, 100000)
                                                                                                                                                                                                                                                                                                                                                                                               returning count into r;
                                                                                                                                                                                                                                                                                                                                                                                                 delete from public.daily_new_counters where user_id = v and day < d - 7;
                                                                                                                                                                                                                                                                                                                                                                                                   return r;
                                                                                                                                                                                                                                                                                                                                                                                                   end $$;


ALTER FUNCTION "public"."increment_new_counter"("p_day" "date", "p_by" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                          select exists (select 1 from public.admins where user_id = auth.uid())
                                                                                                                          $$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."owns_deck"("p" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                              select exists (select 1 from public.decks where id = p and user_id = auth.uid())
                                                                                                                              $$;


ALTER FUNCTION "public"."owns_deck"("p" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."owns_folder"("p_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  select exists (select 1 from public.folders where id = p_id and user_id = auth.uid());
  $$;


ALTER FUNCTION "public"."owns_folder"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $_$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  declare
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    v_uid uuid := auth.uid();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      v_len integer;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        v_upd bigint := 0;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          v_new bigint := 0;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_left bigint;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              v_take bigint;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                v_day date;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  k record;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    if v_uid is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      p_rows   := coalesce(p_rows, '[]'::jsonb);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        p_counts := coalesce(p_counts, '{}'::jsonb);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          if jsonb_typeof(p_rows) = 'null' then p_rows := '[]'::jsonb; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            if jsonb_typeof(p_counts) = 'null' then p_counts := '{}'::jsonb; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              if jsonb_typeof(p_rows) <> 'array' or jsonb_typeof(p_counts) <> 'object' then raise exception 'bad data'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                v_len := jsonb_array_length(p_rows);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  if v_len > 500 then raise exception 'too large'; end if;

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    if v_len > 0 then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        p_rows := (select coalesce(jsonb_agg(e.v), '[]'::jsonb)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       from jsonb_array_elements(p_rows) as e(v) where jsonb_typeof(e.v) = 'object');

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           with r as (
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 select distinct on (x.id) x.*
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       from jsonb_to_recordset(p_rows) as x(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               id uuid, state text, step integer, ease numeric, ivl_days numeric, reps integer, lapses integer,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       due timestamptz, last_review timestamptz, first_seen timestamptz)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             where x.id is not null and x.state in ('learning','review','relearning')
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   order by x.id, x.last_review desc nulls last
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ), cur as (
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             select c.id, (c.first_seen is null) as unseen
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   from public.cards c join r on r.id = c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         where c.user_id = v_uid
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ), upd as (
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   update public.cards c set
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           state       = r.state,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   step        = greatest(coalesce(r.step, 0), 0),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ease        = least(3, greatest(1.3, coalesce(r.ease, c.ease))),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ivl_days    = greatest(coalesce(r.ivl_days, c.ivl_days), 0),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           reps        = greatest(c.reps, coalesce(r.reps, c.reps)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   lapses      = greatest(c.lapses, coalesce(r.lapses, c.lapses)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           due         = coalesce(r.due, c.due),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   last_review = coalesce(r.last_review, c.last_review),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           first_seen  = coalesce(c.first_seen, r.first_seen)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 from r
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       where c.id = r.id and c.user_id = v_uid
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             returning c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 )
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     select (select count(*) from upd),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (select count(*) from cur join r on r.id = cur.id where cur.unseen and r.first_seen is not null)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    into v_upd, v_new;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      end if;

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        if v_new > 0 and p_counts <> '{}'::jsonb then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_left := v_new;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                for k in
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      select e.key as d, (e.value #>> '{}')::integer as n
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            from jsonb_each(p_counts) e
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  where e.key ~ '^\d{4}-\d{2}-\d{2}$' and (e.value #>> '{}') ~ '^\d{1,6}$'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        order by e.key
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            loop
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  exit when v_left <= 0;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                v_day  := k.d::date;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        v_take := least(v_left, greatest(least(k.n, 5000), 0));
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                if v_take > 0 and v_day between current_date - 14 and current_date + 2 then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          insert into public.new_counts (user_id, day, n) values (v_uid, v_day, v_take)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    on conflict (user_id, day) do update set n = public.new_counts.n + excluded.n;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              v_left := v_left - v_take;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            exception when invalid_datetime_format or datetime_field_overflow then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    null;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          end;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              end loop;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  delete from public.new_counts nc where nc.user_id = v_uid and nc.day < current_date - 14;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    end if;

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      return jsonb_build_object('updated', v_upd, 'new', v_new);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      end $_$;


ALTER FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
  tbl name;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        SELECT c.relname INTO tbl FROM pg_catalog.pg_class c WHERE c.oid = cmd.objid;
        EXECUTE format('alter table if exists %I.%I enable row level security', cmd.schema_name, tbl);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."touch_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$ begin new.updated_at = now(); return new; end $$;


ALTER FUNCTION "public"."touch_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."admins" (
    "user_id" "uuid" NOT NULL,
    "added_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "key" "text" NOT NULL,
    "value" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deck_id" "uuid" NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "front" "text" NOT NULL,
    "back" "text" NOT NULL,
    "state" "text" DEFAULT 'new'::"text" NOT NULL,
    "ease" numeric(4,2) DEFAULT 2.50 NOT NULL,
    "ivl_days" numeric(6,2) DEFAULT 0 NOT NULL,
    "reps" integer DEFAULT 0 NOT NULL,
    "lapses" integer DEFAULT 0 NOT NULL,
    "last_review" timestamp with time zone,
    "due" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "step" smallint DEFAULT 0 NOT NULL,
    "first_seen" timestamp with time zone,
    CONSTRAINT "cards_back_check" CHECK ((("char_length"("back") >= 1) AND ("char_length"("back") <= 4000))),
    CONSTRAINT "cards_ease_check" CHECK ((("ease" >= 1.30) AND ("ease" <= 5.00))),
    CONSTRAINT "cards_front_check" CHECK ((("char_length"("front") >= 1) AND ("char_length"("front") <= 2000))),
    CONSTRAINT "cards_state_check" CHECK (("state" = ANY (ARRAY['new'::"text", 'learning'::"text", 'review'::"text", 'relearning'::"text"])))
);


ALTER TABLE "public"."cards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_new" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "day" "date" NOT NULL,
    "n" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."daily_new" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_new_counters" (
    "user_id" "uuid" NOT NULL,
    "day" "date" NOT NULL,
    "count" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "daily_new_counters_count_check" CHECK (("count" >= 0))
);


ALTER TABLE "public"."daily_new_counters" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."decks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "name" "text" NOT NULL,
    "color" "text" DEFAULT 'blue'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "folder_id" "uuid",
    "srs_enabled" boolean DEFAULT true NOT NULL,
    CONSTRAINT "decks_name_check" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 120)))
);


ALTER TABLE "public"."decks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."folders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "parent_id" "uuid",
    "name" "text" NOT NULL,
    "icon" "text" DEFAULT 'folder'::"text" NOT NULL,
    "color" "text" DEFAULT 'blue'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "folders_name_check" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 120)))
);


ALTER TABLE "public"."folders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."new_counts" (
    "user_id" "uuid" NOT NULL,
    "day" "date" NOT NULL,
    "n" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."new_counts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shares" (
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "cards" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "kind" "text" DEFAULT 'deck'::"text" NOT NULL,
    "user_id" "uuid"
);


ALTER TABLE "public"."shares" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_settings" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "learning_steps" "text" DEFAULT '1m,10m,1d'::"text" NOT NULL,
    "max_interval" integer DEFAULT 365 NOT NULL,
    "new_per_day" integer DEFAULT 20 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "step_again" integer DEFAULT 1 NOT NULL,
    "step_hard" integer DEFAULT 10 NOT NULL,
    "step_good" integer DEFAULT 1440 NOT NULL,
    "step_easy" integer DEFAULT 5760 NOT NULL,
    CONSTRAINT "user_settings_learning_steps_check" CHECK (("char_length"("learning_steps") <= 60)),
    CONSTRAINT "user_settings_max_interval_check" CHECK ((("max_interval" >= 1) AND ("max_interval" <= 3650))),
    CONSTRAINT "user_settings_new_per_day_check" CHECK ((("new_per_day" >= 0) AND ("new_per_day" <= 500)))
);


ALTER TABLE "public"."user_settings" OWNER TO "postgres";


ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("key");



ALTER TABLE "public"."cards"
    ADD CONSTRAINT "cards_len_chk" CHECK (((("char_length"("front") >= 1) AND ("char_length"("front") <= 2000)) AND (("char_length"("back") >= 1) AND ("char_length"("back") <= 4000)))) NOT VALID;



ALTER TABLE ONLY "public"."cards"
    ADD CONSTRAINT "cards_pkey" PRIMARY KEY ("id");



ALTER TABLE "public"."cards"
    ADD CONSTRAINT "cards_state_chk" CHECK (("state" = ANY (ARRAY['new'::"text", 'learning'::"text", 'review'::"text", 'relearning'::"text"]))) NOT VALID;



ALTER TABLE ONLY "public"."daily_new_counters"
    ADD CONSTRAINT "daily_new_counters_pkey" PRIMARY KEY ("user_id", "day");



ALTER TABLE ONLY "public"."daily_new"
    ADD CONSTRAINT "daily_new_pkey" PRIMARY KEY ("user_id", "day");



ALTER TABLE "public"."decks"
    ADD CONSTRAINT "decks_name_chk" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 120))) NOT VALID;



ALTER TABLE ONLY "public"."decks"
    ADD CONSTRAINT "decks_pkey" PRIMARY KEY ("id");



ALTER TABLE "public"."folders"
    ADD CONSTRAINT "folders_name_chk" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 120))) NOT VALID;



ALTER TABLE ONLY "public"."folders"
    ADD CONSTRAINT "folders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."new_counts"
    ADD CONSTRAINT "new_counts_pkey" PRIMARY KEY ("user_id", "day");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."user_settings"
    ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id");



ALTER TABLE "public"."user_settings"
    ADD CONSTRAINT "user_settings_rng_chk" CHECK (((("max_interval" >= 1) AND ("max_interval" <= 3650)) AND (("new_per_day" >= 0) AND ("new_per_day" <= 500)) AND (("step_again" >= 1) AND ("step_again" <= 5256000)) AND (("step_hard" >= 1) AND ("step_hard" <= 5256000)) AND (("step_good" >= 1) AND ("step_good" <= 5256000)) AND (("step_easy" >= 1) AND ("step_easy" <= 5256000)))) NOT VALID;



ALTER TABLE "public"."user_settings"
    ADD CONSTRAINT "user_settings_steps_chk" CHECK ((("step_again" >= 1) AND ("step_easy" <= 5256000) AND ("step_again" <= "step_hard") AND ("step_hard" <= "step_good") AND ("step_good" <= "step_easy"))) NOT VALID;



CREATE INDEX "cards_deck_created_idx" ON "public"."cards" USING "btree" ("deck_id", "created_at", "id");



CREATE INDEX "cards_deck_due_idx" ON "public"."cards" USING "btree" ("deck_id", "due") WHERE ("state" <> 'new'::"text");



CREATE INDEX "cards_deck_idx" ON "public"."cards" USING "btree" ("deck_id", "created_at", "id");



CREATE INDEX "cards_deck_order_idx" ON "public"."cards" USING "btree" ("deck_id", "created_at", "id");



CREATE INDEX "cards_due_idx" ON "public"."cards" USING "btree" ("deck_id", "due") WHERE ("state" <> 'new'::"text");



CREATE INDEX "cards_new_idx" ON "public"."cards" USING "btree" ("deck_id", "created_at", "id") WHERE ("state" = 'new'::"text");



CREATE INDEX "cards_user_deck_idx" ON "public"."cards" USING "btree" ("user_id", "deck_id") INCLUDE ("state", "due");



CREATE INDEX "decks_folder_idx" ON "public"."decks" USING "btree" ("folder_id");



CREATE INDEX "decks_user_idx" ON "public"."decks" USING "btree" ("user_id");



CREATE INDEX "folders_parent_idx" ON "public"."folders" USING "btree" ("parent_id");



CREATE INDEX "folders_user_idx" ON "public"."folders" USING "btree" ("user_id");



CREATE INDEX "shares_user_idx" ON "public"."shares" USING "btree" ("user_id", "created_at" DESC);



CREATE OR REPLACE TRIGGER "trg_cards_touch" BEFORE UPDATE ON "public"."cards" FOR EACH ROW EXECUTE FUNCTION "public"."touch_updated_at"();



CREATE OR REPLACE TRIGGER "trg_decks_touch" BEFORE UPDATE ON "public"."decks" FOR EACH ROW EXECUTE FUNCTION "public"."touch_updated_at"();



ALTER TABLE ONLY "public"."cards"
    ADD CONSTRAINT "cards_deck_id_fkey" FOREIGN KEY ("deck_id") REFERENCES "public"."decks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."daily_new_counters"
    ADD CONSTRAINT "daily_new_counters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."decks"
    ADD CONSTRAINT "decks_folder_id_fkey" FOREIGN KEY ("folder_id") REFERENCES "public"."folders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."folders"
    ADD CONSTRAINT "folders_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."folders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."new_counts"
    ADD CONSTRAINT "new_counts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cards" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cards_del" ON "public"."cards" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "cards_ins" ON "public"."cards" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."decks" "d"
  WHERE (("d"."id" = "cards"."deck_id") AND ("d"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "cards_sel" ON "public"."cards" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "cards_upd" ON "public"."cards" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."decks" "d"
  WHERE (("d"."id" = "cards"."deck_id") AND ("d"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "config_del" ON "public"."app_config" FOR DELETE TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "config_ins" ON "public"."app_config" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin"());



CREATE POLICY "config_sel" ON "public"."app_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "config_upd" ON "public"."app_config" FOR UPDATE TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "counters_read" ON "public"."daily_new_counters" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."daily_new" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."daily_new_counters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."decks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "decks_del" ON "public"."decks" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "decks_ins" ON "public"."decks" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (("folder_id" IS NULL) OR "public"."owns_folder"("folder_id"))));



CREATE POLICY "decks_sel" ON "public"."decks" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "decks_upd" ON "public"."decks" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (("folder_id" IS NULL) OR "public"."owns_folder"("folder_id"))));



ALTER TABLE "public"."folders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "folders_del" ON "public"."folders" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "folders_ins" ON "public"."folders" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (("parent_id" IS NULL) OR "public"."owns_folder"("parent_id"))));



CREATE POLICY "folders_sel" ON "public"."folders" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "folders_upd" ON "public"."folders" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (("parent_id" IS NULL) OR "public"."owns_folder"("parent_id"))));



ALTER TABLE "public"."new_counts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pc_own" ON "public"."daily_new" TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "settings_ins" ON "public"."user_settings" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "settings_sel" ON "public"."user_settings" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "settings_upd" ON "public"."user_settings" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."shares" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_settings" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































REVOKE ALL ON FUNCTION "public"."admin_stats"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_stats"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb", "p_folder" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb", "p_folder" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb", "p_folder" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer, "p_new_limit" integer, "p_day" "date", "p_exclude" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer, "p_new_limit" integer, "p_day" "date", "p_exclude" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer, "p_new_limit" integer, "p_day" "date", "p_exclude" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."est_rows"("p" "regclass") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."est_rows"("p" "regclass") TO "service_role";



REVOKE ALL ON FUNCTION "public"."folder_tree"("p_user" "uuid", "p_root" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."folder_tree"("p_user" "uuid", "p_root" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_share"("p_code" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_share"("p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_share"("p_code" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."home_snapshot"("p_day" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."home_snapshot"("p_day" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."home_snapshot"("p_day" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."increment_new_counter"("p_day" "date", "p_by" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."increment_new_counter"("p_day" "date", "p_by" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_new_counter"("p_day" "date", "p_by" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."owns_deck"("p" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."owns_deck"("p" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."owns_deck"("p" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."owns_folder"("p_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."owns_folder"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."owns_folder"("p_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."admins" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."cards" TO "authenticated";
GRANT ALL ON TABLE "public"."cards" TO "service_role";



GRANT ALL ON TABLE "public"."daily_new" TO "anon";
GRANT ALL ON TABLE "public"."daily_new" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_new" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."daily_new_counters" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_new_counters" TO "service_role";



GRANT ALL ON TABLE "public"."decks" TO "authenticated";
GRANT ALL ON TABLE "public"."decks" TO "service_role";



GRANT ALL ON TABLE "public"."folders" TO "authenticated";
GRANT ALL ON TABLE "public"."folders" TO "service_role";



GRANT ALL ON TABLE "public"."new_counts" TO "service_role";



GRANT ALL ON TABLE "public"."shares" TO "service_role";



GRANT ALL ON TABLE "public"."user_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."user_settings" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































