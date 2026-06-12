


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



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."branch_type" AS ENUM (
    'juz',
    'ru',
    'taipa',
    'ata',
    'ul'
);


ALTER TYPE "public"."branch_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_ancestors"("person_id" "text") RETURNS TABLE("id" "text", "name" "text", "depth" integer)
    LANGUAGE "sql"
    AS $$
    WITH RECURSIVE ancestors AS (
        SELECT id, name, parent_id, depth, 0 as level
        FROM people
        WHERE id = person_id
        
        UNION ALL
        
        SELECT p.id, p.name, p.parent_id, p.depth, a.level + 1
        FROM people p
        INNER JOIN ancestors a ON p.id = a.parent_id
    )
    SELECT id, name, depth
    FROM ancestors
    ORDER BY level DESC;
$$;


ALTER FUNCTION "public"."get_ancestors"("person_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_descendants"("person_id" "text") RETURNS TABLE("id" "text", "name" "text", "depth" integer)
    LANGUAGE "sql"
    AS $$
    WITH RECURSIVE descendants AS (
        SELECT id, name, parent_id, depth, 0 as level
        FROM people
        WHERE id = person_id
        
        UNION ALL
        
        SELECT p.id, p.name, p.parent_id, p.depth, d.level + 1
        FROM people p
        INNER JOIN descendants d ON p.parent_id = d.id
    )
    SELECT id, name, depth
    FROM descendants
    ORDER BY level;
$$;


ALTER FUNCTION "public"."get_descendants"("person_id" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."people" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "parent_id" "text",
    "depth" integer DEFAULT 0,
    "path" "text",
    "author" "text",
    "image" "text",
    "birth_year" integer,
    "death_year" integer,
    "meta_status" "text",
    "locked" "text",
    "orderby" "text",
    "children_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."people" OWNER TO "postgres";


COMMENT ON TABLE "public"."people" IS 'Генеалогическое дерево казахского народа из tumalas.kz';



COMMENT ON COLUMN "public"."people"."id" IS 'Уникальный ID из источника';



COMMENT ON COLUMN "public"."people"."parent_id" IS 'ID родителя (NULL для корневого элемента)';



COMMENT ON COLUMN "public"."people"."depth" IS 'Глубина в дереве (0 = корень)';



COMMENT ON COLUMN "public"."people"."path" IS 'Полный путь от корня через > ';



ALTER TABLE ONLY "public"."people"
    ADD CONSTRAINT "people_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_people_depth" ON "public"."people" USING "btree" ("depth");



CREATE INDEX "idx_people_name" ON "public"."people" USING "btree" ("name");



CREATE INDEX "idx_people_parent_id" ON "public"."people" USING "btree" ("parent_id");



CREATE INDEX "idx_people_path" ON "public"."people" USING "gin" ("to_tsvector"('"russian"'::"regconfig", "path"));



ALTER TABLE ONLY "public"."people"
    ADD CONSTRAINT "people_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



CREATE POLICY "Allow all for admin" ON "public"."people" TO "authenticated" USING ((("auth"."jwt"() ->> 'email'::"text") = 'test@gmail.com'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'email'::"text") = 'test@gmail.com'::"text"));



CREATE POLICY "Allow read access for all" ON "public"."people" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."people" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."get_ancestors"("person_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_ancestors"("person_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ancestors"("person_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_descendants"("person_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_descendants"("person_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_descendants"("person_id" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."people" TO "anon";
GRANT ALL ON TABLE "public"."people" TO "authenticated";
GRANT ALL ON TABLE "public"."people" TO "service_role";









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































drop extension if exists "pg_net";

drop policy "Allow read access for all" on "public"."people";


  create policy "Allow read access for all"
  on "public"."people"
  as permissive
  for select
  to anon, authenticated
using (true);



