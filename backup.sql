


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


CREATE OR REPLACE FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_exclude" "uuid"[]) RETURNS TABLE("id" "uuid", "deck_id" "uuid", "front" "text", "back" "text", "state" "text", "step" integer, "ease" real, "ivl_days" real, "reps" integer, "lapses" integer, "due" timestamp with time zone, "last_review" timestamp with time zone, "first_seen" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     #variable_conflict use_column
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     declare v uuid := auth.uid(); ex uuid[] := coalesce(p_exclude, '{}');
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       if v is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           select c.id, c.deck_id, c.front, c.back, c.state::text, c.step::int, c.ease::real, c.ivl_days::real,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    c.reps::int, c.lapses::int, c.due::timestamptz, c.last_review::timestamptz, c.first_seen::timestamptz
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        where c.user_id = v and c.deck_id = p_deck and c.id <> all (ex)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          order by random() limit least(greatest(coalesce(p_limit, 30), 1), 100);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          end $$;


ALTER FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_exclude" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text" DEFAULT ''::"text", "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "deck_id" "uuid", "front" "text", "back" "text", "state" "text", "step" integer, "ease" real, "ivl_days" real, "reps" integer, "lapses" integer, "due" timestamp with time zone, "last_review" timestamp with time zone, "first_seen" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    AS $$
                                                            declare v uuid := auth.uid();
                                                            begin
                                                              if v is null then raise exception 'auth required'; end if;
                                                                return query
                                                                  select c.id, c.deck_id, c.front, c.back, c.state::text, c.step::int, c.ease::real, c.ivl_days::real, c.reps::int, c.lapses::int, c.due::timestamptz, c.last_review::timestamptz, c.first_seen::timestamptz
                                                                    from public.cards c
                                                                      where c.user_id = v and c.deck_id = p_deck
                                                                        order by md5(c.id::text || p_seed) -- ترتيب عشوائي ثابت
                                                                          limit least(greatest(coalesce(p_limit, 30), 1), 100)
                                                                            offset greatest(coalesce(p_offset, 0), 0);
                                                                            end $$;


ALTER FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb" DEFAULT NULL::"jsonb", "p_folder" "uuid" DEFAULT NULL::"uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          declare v uuid := auth.uid(); nm text := left(trim(coalesce(p_name, '')), 120);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  payload jsonb; kd text; k text; nf int; nd int; nc int;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    if v is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      if nm = '' then raise exception 'bad name'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        if (select count(*) from public.shares where owner = v and created_at > now() - interval '60 seconds') >= 5
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            then raise exception 'rate limited'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              if p_folder is not null then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  kd := 'folder';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      select count(*), (select count(*) from public.decks d where d.user_id = v
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            and d.folder_id in (select t.id from public.folder_tree(v, p_folder) t)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       (select count(*) from public.cards c join public.decks d on d.id = c.deck_id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   where c.user_id = v and d.folder_id in (select t.id from public.folder_tree(v, p_folder) t))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         into nf, nd, nc from public.folder_tree(v, p_folder);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             if nf = 0 or nd = 0 then raise exception 'bad data'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 if nf > 200 or nd > 200 or nc > 5000 then raise exception 'too large'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     payload := jsonb_build_object(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           'folders', (select jsonb_agg(jsonb_build_object('name', t.name, 'icon', t.icon, 'color', t.color, 'parent', p.idx) order by t.idx)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             from public.folder_tree(v, p_folder) t left join public.folder_tree(v, p_folder) p on p.id = t.parent_id),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   'decks', (select jsonb_agg(jsonb_build_object('name', d.name, 'color', d.color, 'folder', t.idx,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'cards', (select coalesce(jsonb_agg(jsonb_build_object('front', c.front, 'back', c.back) order by c.created_at, c.id), '[]'::jsonb)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 from public.cards c where c.deck_id = d.id and c.user_id = v)) order by t.idx, d.created_at)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 from public.decks d join public.folder_tree(v, p_folder) t on t.id = d.folder_id where d.user_id = v));
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   else
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       kd := 'deck'; payload := p_cards;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           if payload is null or jsonb_typeof(payload) <> 'array' or jsonb_array_length(payload) < 1
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  or jsonb_array_length(payload) > 1000 then raise exception 'bad cards'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      if octet_length(payload::text) > 5242880 then raise exception 'too large'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        for i in 1..5 loop
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            k := substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      insert into public.shares (code, owner, name, kind, cards) values (k, v, nm, kd, payload);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            return k;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                exception when unique_violation then null;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    end;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      end loop;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        raise exception 'bad data';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        end $$;


ALTER FUNCTION "public"."create_share"("p_name" "text", "p_cards" "jsonb", "p_folder" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."due_batch"("p_deck" "uuid", "p_limit" integer, "p_new_limit" integer, "p_day" "date", "p_exclude" "uuid"[]) RETURNS TABLE("id" "uuid", "deck_id" "uuid", "front" "text", "back" "text", "state" "text", "step" integer, "ease" real, "ivl_days" real, "reps" integer, "lapses" integer, "due" timestamp with time zone, "last_review" timestamp with time zone, "first_seen" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                                                                                                                                                                                 #variable_conflict use_column
                                                                                                                                                                                                                                                                                                                                                                                                                 declare v uuid := auth.uid(); lim int := least(greatest(coalesce(p_limit, 30), 1), 100);
                                                                                                                                                                                                                                                                                                                                                                                                                         ex uuid[] := coalesce(p_exclude, '{}'); used int; left_new int;
                                                                                                                                                                                                                                                                                                                                                                                                                         begin
                                                                                                                                                                                                                                                                                                                                                                                                                           if v is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                             select coalesce((select n.count from public.daily_new_counters n
                                                                                                                                                                                                                                                                                                                                                                                                                                                where n.user_id = v and n.day = coalesce(p_day, current_date)), 0) into used;
                                                                                                                                                                                                                                                                                                                                                                                                                                                  left_new := greatest(0, least(greatest(coalesce(p_new_limit, 20), 0), 500) - used);
                                                                                                                                                                                                                                                                                                                                                                                                                                                    return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                      with d as (
                                                                                                                                                                                                                                                                                                                                                                                                                                                          select c.id, c.deck_id, c.front, c.back, c.state::text as state, c.step::int as step, c.ease::real as ease,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     c.ivl_days::real as ivl_days, c.reps::int as reps, c.lapses::int as lapses, c.due::timestamptz as due,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                c.last_review::timestamptz as last_review, c.first_seen::timestamptz as first_seen
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        where c.user_id = v and c.deck_id = p_deck and c.state <> 'new' and c.due <= now() and c.id <> all (ex)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            order by c.due limit lim),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              n as (
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  select c.id, c.deck_id, c.front, c.back, c.state::text as state, c.step::int as step, c.ease::real as ease,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             c.ivl_days::real as ivl_days, c.reps::int as reps, c.lapses::int as lapses, c.due::timestamptz as due,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        c.last_review::timestamptz as last_review, c.first_seen::timestamptz as first_seen
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            from public.cards c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                where c.user_id = v and c.deck_id = p_deck and c.state = 'new' and c.id <> all (ex)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    order by c.created_at, c.id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        limit greatest(0, least(left_new, lim - (select count(*) from d))::int))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          select u.id, u.deck_id, u.front, u.back, u.state, u.step, u.ease, u.ivl_days, u.reps, u.lapses,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   u.due, u.last_review, u.first_seen
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     from (select 0 as o, d.* from d union all select 1 as o, n.* from n) u
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       order by u.o, u.due, u.id;
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


CREATE OR REPLACE FUNCTION "public"."get_share"("p_code" "text") RETURNS TABLE("name" "text", "cards" "jsonb", "kind" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        #variable_conflict use_column
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          if auth.uid() is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            if p_code is null or lower(p_code) !~ '^[0-9a-f]{6,8}$' then return; end if;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              return query
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                with u as (update public.shares s set uses = s.uses + 1 where s.code = lower(p_code)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             returning s.name, s.cards, s.kind)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               select u.name, u.cards, u.kind from u;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               end $_$;


ALTER FUNCTION "public"."get_share"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."home_snapshot"("p_day" "date" DEFAULT NULL::"date") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
                                                                                                                                                                                                                                                     declare v uuid := auth.uid(); d date := coalesce(p_day, current_date);
                                                                                                                                                                                                                                                     begin
                                                                                                                                                                                                                                                       if v is null then raise exception 'auth required'; end if;
                                                                                                                                                                                                                                                         return jsonb_build_object(
                                                                                                                                                                                                                                                             'decks', coalesce((select jsonb_agg(jsonb_build_object('id', k.id, 'name', k.name, 'color', k.color,
                                                                                                                                                                                                                                                                     'folder_id', k.folder_id, 'srs_enabled', k.srs_enabled, 'created_at', k.created_at) order by k.created_at desc)
                                                                                                                                                                                                                                                                           from public.decks k where k.user_id = v), '[]'::jsonb),
                                                                                                                                                                                                                                                                               'folders', coalesce((select jsonb_agg(jsonb_build_object('id', f.id, 'name', f.name, 'icon', f.icon,
                                                                                                                                                                                                                                                                                       'color', f.color, 'parent_id', f.parent_id) order by f.created_at)
                                                                                                                                                                                                                                                                                             from public.folders f where f.user_id = v), '[]'::jsonb),
                                                                                                                                                                                                                                                                                                 'counts', coalesce((select jsonb_object_agg(x.deck_id, jsonb_build_object('total', x.t, 'due', x.du, 'new', x.nw))
                                                                                                                                                                                                                                                                                                       from (select c.deck_id, count(*) as t,
                                                                                                                                                                                                                                                                                                                          count(*) filter (where c.state <> 'new' and c.due <= now()) as du,
                                                                                                                                                                                                                                                                                                                                             count(*) filter (where c.state = 'new') as nw
                                                                                                                                                                                                                                                                                                                                                         from public.cards c where c.user_id = v group by c.deck_id) x), '{}'::jsonb),
                                                                                                                                                                                                                                                                                                                                                             'settings', (select jsonb_build_object('new_per_day', s.new_per_day, 'max_interval', s.max_interval,
                                                                                                                                                                                                                                                                                                                                                                     'step_again', s.step_again, 'step_hard', s.step_hard, 'step_good', s.step_good, 'step_easy', s.step_easy)
                                                                                                                                                                                                                                                                                                                                                                           from public.user_settings s where s.user_id = v),
                                                                                                                                                                                                                                                                                                                                                                               'new_today', coalesce((select n.count from public.daily_new_counters n where n.user_id = v and n.day = d), 0)
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


CREATE OR REPLACE FUNCTION "public"."owns_folder"("p" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
                                                                                                                            select p is null or exists (select 1 from public.folders where id = p and user_id = auth.uid())
                                                                                                                            $$;


ALTER FUNCTION "public"."owns_folder"("p" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
declare v uuid := auth.uid(); r jsonb; k text; v_count int;
begin
  if v is null then raise exception 'auth required'; end if;
    
      -- تحديث البطاقات
        for r in select * from jsonb_array_elements(p_rows) loop
            update public.cards set 
                  state = r->>'state', step = (r->>'step')::int, ease = (r->>'ease')::real, 
                        ivl_days = (r->>'ivl_days')::real, reps = (r->>'reps')::int, lapses = (r->>'lapses')::int, 
                              due = (r->>'due')::timestamptz, last_review = (r->>'last_review')::timestamptz,
                                    first_seen = coalesce((r->>'first_seen')::timestamptz, first_seen)
                                        where id = (r->>'id')::uuid and user_id = v;
                                          end loop;

                                            -- تحديث عداد البطاقات الجديدة
                                              for k, v_count in select * from jsonb_each_text(p_counts) loop
                                                  insert into public.daily_new_counters (user_id, day, count)
                                                      values (v, k::date, v_count::int)
                                                          on conflict (user_id, day) do update set count = public.daily_new_counters.count + excluded.count;
                                                            end loop;
                                                            end $$;


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


CREATE TABLE IF NOT EXISTS "public"."shares" (
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "cards" "jsonb" NOT NULL,
    "owner" "uuid" NOT NULL,
    "uses" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "kind" "text" DEFAULT 'deck'::"text" NOT NULL
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



ALTER TABLE ONLY "public"."cards"
    ADD CONSTRAINT "cards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_new_counters"
    ADD CONSTRAINT "daily_new_counters_pkey" PRIMARY KEY ("user_id", "day");



ALTER TABLE ONLY "public"."decks"
    ADD CONSTRAINT "decks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."folders"
    ADD CONSTRAINT "folders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."user_settings"
    ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id");



ALTER TABLE "public"."user_settings"
    ADD CONSTRAINT "user_settings_steps_chk" CHECK ((("step_again" >= 1) AND ("step_easy" <= 5256000) AND ("step_again" <= "step_hard") AND ("step_hard" <= "step_good") AND ("step_good" <= "step_easy"))) NOT VALID;



CREATE INDEX "cards_deck_due_idx" ON "public"."cards" USING "btree" ("deck_id", "due") WHERE ("state" <> 'new'::"text");



CREATE INDEX "cards_deck_idx" ON "public"."cards" USING "btree" ("deck_id", "created_at", "id");



CREATE INDEX "cards_user_deck_idx" ON "public"."cards" USING "btree" ("user_id", "deck_id") INCLUDE ("state", "due");



CREATE INDEX "decks_folder_idx" ON "public"."decks" USING "btree" ("folder_id");



CREATE INDEX "decks_user_idx" ON "public"."decks" USING "btree" ("user_id");



CREATE INDEX "folders_parent_idx" ON "public"."folders" USING "btree" ("parent_id");



CREATE INDEX "folders_user_idx" ON "public"."folders" USING "btree" ("user_id");



CREATE INDEX "idx_shares_owner_time" ON "public"."shares" USING "btree" ("owner", "created_at" DESC);



CREATE INDEX "shares_owner_idx" ON "public"."shares" USING "btree" ("owner", "created_at");



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



ALTER TABLE "public"."admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cards" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cards_own" ON "public"."cards" TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."owns_deck"("deck_id")));



CREATE POLICY "config_del" ON "public"."app_config" FOR DELETE TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "config_ins" ON "public"."app_config" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin"());



CREATE POLICY "config_read" ON "public"."app_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "config_upd" ON "public"."app_config" FOR UPDATE TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "counters_read" ON "public"."daily_new_counters" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."daily_new_counters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."decks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "decks_own" ON "public"."decks" TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."owns_folder"("folder_id")));



ALTER TABLE "public"."folders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "folders_own" ON "public"."folders" TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."owns_folder"("parent_id")));



CREATE POLICY "settings_own" ON "public"."user_settings" TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."shares" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "shares_read" ON "public"."shares" FOR SELECT TO "authenticated" USING (("owner" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."user_settings" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































REVOKE ALL ON FUNCTION "public"."admin_stats"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_stats"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_exclude" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_exclude" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_exclude" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."cram_batch"("p_deck" "uuid", "p_limit" integer, "p_seed" "text", "p_offset" integer) TO "anon";
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



REVOKE ALL ON FUNCTION "public"."owns_folder"("p" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."owns_folder"("p" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."owns_folder"("p" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."review_batch"("p_rows" "jsonb", "p_counts" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."admins" TO "authenticated";
GRANT ALL ON TABLE "public"."admins" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."cards" TO "authenticated";
GRANT ALL ON TABLE "public"."cards" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."daily_new_counters" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_new_counters" TO "service_role";



GRANT ALL ON TABLE "public"."decks" TO "authenticated";
GRANT ALL ON TABLE "public"."decks" TO "service_role";



GRANT ALL ON TABLE "public"."folders" TO "authenticated";
GRANT ALL ON TABLE "public"."folders" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."shares" TO "authenticated";
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



































