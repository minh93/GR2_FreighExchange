--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: pgrouting; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgrouting WITH SCHEMA public;


--
-- Name: EXTENSION pgrouting; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgrouting IS 'pgRouting Extension';


SET search_path = public, pg_catalog;

--
-- Name: check_category(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_category() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE category_id1 int;
DECLARE category_id2 int;
BEGIN
	category_id1 = (SELECT v.category_id
	FROM vehicle AS v 
	INNER JOIN trip AS t
	ON v.vehicle_id = t.vehicle_id
	WHERE t.trip_id = NEW.trip_id);

	category_id2 = (SELECT ab.category_id
	FROM abstract_trip AS ab
	INNER JOIN trip AS t
	ON ab.ab_trip_id = t.ab_trip_id
	WHERE t.trip_id = NEW.trip_id);

	IF(category_id1 <> category_id2) THEN
		 RAISE EXCEPTION 'trip has different categories %, %', category_id1, category_id2;
	END IF;
	RETURN NEW;
END;
$$;


--
-- Name: check_point(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_point() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE count1 int;

DECLARE point1 int;

BEGIN
	IF(NEW.sequent > 1) THEN
		count1 = NEW.sequent - 1;
	
		point1 = (SELECT ab.end_point
		FROM abstract_trip AS ab 
		INNER JOIN trip AS t
		ON ab.ab_trip_id = t.ab_trip_id
		WHERE t.sequent = count1 AND t.schedule = NEW.schedule);

		IF(point1 <> NEW.start_point) THEN
			RAISE EXCEPTION 'sequence is not right';
		END IF;
		RETURN NEW;
	END IF;
	RETURN NEW;
END 
$$;


--
-- Name: check_request_time(interval, interval, interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_request_time(remind1 interval, remind2 interval, expired interval) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE timeTilNow interval; 
DECLARE n integer;
DECLARE i integer;
DECLARE idNone int[];
DECLARE idRemind1 int[];
DECLARE idRemind2 int[];
BEGIN
	-- check requests have status 'none' or 'pending'
	idNone =(SELECT ARRAY(SELECT request_id FROM request WHERE status = 'none' OR status = 'pending'));
	n = (SELECT count(*) FROM request WHERE status = 'none' OR status = 'pending'); --count none status request
	FOR i in 0..n-1 LOOP
		timeTilNow = (SELECT (CURRENT_TIMESTAMP - (SELECT updated_at FROM request WHERE request_id = idNone[i])));
		IF(timeTilNow >  expired) THEN UPDATE request SET status = 'expired' WHERE request_id = idNone[i];
		ELSEIF(timeTilNow >  remind2 ) THEN UPDATE request SET status = 'remind2' WHERE request_id = idNone[i];
		ELSEIF(timeTilNow >  remind1 ) THEN UPDATE request SET status = 'remind1' WHERE request_id = idNone[i];
		END IF;
	END LOOP;

	--check requests have status 'remind1'
	idRemind1 = (SELECT ARRAY(SELECT request_id FROM request WHERE status = 'remind1'));
	n = (SELECT count(*) FROM request WHERE status = 'remind1'); --count none status request
	FOR i in 0..n-1 LOOP
		timeTilNow = (SELECT (CURRENT_TIMESTAMP - (SELECT updated_at FROM request WHERE request_id = idNone[i])));
		IF(timeTilNow >  expired) THEN UPDATE request SET status = 'expired' WHERE request_id = idNone[i];
		ELSEIF(timeTilNow >  remind2 ) THEN UPDATE request SET status = 'remind2' WHERE request_id = idNone[i];	
		END IF;
	END LOOP;

	--check requests have status 'remind2'
	idRemind2 = (SELECT ARRAY(SELECT request_id FROM request WHERE status = 'remind2'));
	n = (SELECT count(*) FROM request WHERE status = 'remind2'); --count none status request
	FOR i in 0..n-1 LOOP
		timeTilNow = (SELECT (CURRENT_TIMESTAMP - (SELECT updated_at FROM request WHERE request_id = idNone[i])));
		IF(timeTilNow >  expired) THEN UPDATE request SET status = 'expired' WHERE request_id = idNone[i];
		END IF;
	END LOOP;
END;
$$;


--
-- Name: contain_routing(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION contain_routing(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  num_of_node integer;
  start_point geometry(Point,4269);
  end_point geometry(Point,4269);
  source_val integer;
  target_val integer;
begin
  start_point = st_setsrid(st_makePoint(start_lon, start_lat), 4269);
  end_point = st_setsrid(st_makePoint(end_lon, end_lat), 4269);
  select point into start_point from location where st_dwithin(start_point::geography, point::geography, 100) limit 1;
  select point into end_point from location where st_dwithin(end_point::geography, point::geography, 100) limit 1;

  select source into source_val from ways where start_point = st_startpoint(the_geom);
  select target into target_val from ways where end_point = st_endpoint(the_geom);

  raise notice 'source_val(%)', source_val;
  raise notice 'target_val(%)', target_val;

  SELECT count(seq) into num_of_node FROM pgr_dijkstra('
                SELECT abstract_trip_id AS id,
                         source::integer,
                         target::integer,
                         length::double precision AS cost,
                         reverse_cost::double precision AS reverse_cost
                        FROM ways',
                source_val, target_val, true, true);
  return num_of_node;
end
$$;


--
-- Name: create_new_way(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION create_new_way() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE ab_trip_id1 integer;
DECLARE lat1 double precision;
DECLARE long1 double precision;
DECLARE lat2 double precision;
DECLARE long2 double precision;
DECLARE source_name1 text;
DECLARE target_name1 text;
BEGIN
	ab_trip_id1 = (SELECT abstract_trip_id FROM ways WHERE abstract_trip_id = NEW.abstract_trip_id);
	
	long1 = (SELECT ST_X(point::geometry) FROM location WHERE location_id = NEW.start_point);
	lat1 = (SELECT ST_Y(point::geometry) FROM location WHERE location_id = NEW.start_point);

	long2 = (SELECT ST_X(point::geometry) FROM location WHERE location_id = NEW.end_point);
	lat2 = (SELECT ST_Y(point::geometry) FROM location WHERE location_id = NEW.end_point);

	source_name1 = (SELECT address FROM location WHERE location_id = NEW.start_point);
	target_name1 = (SELECT address FROM location WHERE location_id = NEW.end_point);

	IF pg_trigger_depth() <> 1 THEN
		RETURN NEW;
	END IF;

	IF ab_trip_id1 = NEW.abstract_trip_id THEN 
		UPDATE ways set x1 = long1, y1 = lat1, x2 = long2, y2 = lat2, the_geom = (SELECT ST_GeomFromText('LINESTRING('||long1||' '||lat1||','||long2||' '||lat2||')',4269)), 
		source = NEW.start_point, target = NEW.end_point, name = source_name1 || ' - ' || target_name1 
		WHERE abstract_trip_id = ab_trip_id1;
		RETURN NEW;
	ELSE
		INSERT INTO ways(abstract_trip_id, class_id, x1, y1, x2, y2, the_geom, source, target, name) 
		VALUES(NEW.abstract_trip_id, 1, long1, lat1, long2, lat2,(SELECT ST_GeomFromText('LINESTRING('||long1||' '||lat1||','||long2||' '||lat2||')',4269)), 
		NEW.start_point, NEW.end_point, source_name1 || ' - ' || target_name1 );
		RETURN NEW;
	END IF;
END;
$$;


--
-- Name: createlocation(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION createlocation(j integer, k integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    BEGIN
      FOR i in j..k LOOP
	insert into location(radius, location_type, country, city, street, address, point) values(1.5, 1, 'Việt Nam', '', '', (select address from map2 where id = i),
	ST_SetSRID(ST_MakePoint((select longitude from map2 where id = i),(select latitude from map2 where id = i)), 4269));
	
      END LOOP;
    END;
    $$;


--
-- Name: estimate_time(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION estimate_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE sum_time time;
BEGIN
	sum_time = (SELECT SUM(ab.duration) 
	FROM abstract_trip AS ab 
	INNER JOIN trip AS t
	ON t.ab_trip_id = ab.ab_trip_id
	WHERE t.trip_id = NEW.trip_id);

	UPDATE schedule SET estimate_time = sum_time 
	WHERE schedule_id = NEW.schedule_id;
	RETURN NEW;
END;
$$;


--
-- Name: getdistance(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION getdistance(i integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
	Declare distance double precision;
        BEGIN
            distance = ST_Distance_Sphere((select point from location inner join abstract_trip on location.location_id = abstract_trip.start_point where abstract_trip_id = i), 
            (select point from location inner join abstract_trip on location.location_id = abstract_trip.end_point where abstract_trip_id = i));
            RETURN distance;
        END;
$$;


--
-- Name: insert_abstract(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_abstract(m integer, n integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
   
    BEGIN
      FOR i in 1..20 LOOP
		insert into abstract_trip(category_id, start_point, end_point) values(i, m, n);
      END LOOP;
    END;
    $$;


--
-- Name: insert_abstract_trip(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_abstract_trip(m integer, n integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    DECLARE j integer;
    DECLARE k integer;
    BEGIN
      FOR i in 1..20 LOOP
	FOR j in m..n-1 LOOP
		
			insert into abstract_trip(category_id, start_point, end_point) values(i, j, j+1);
		
	END LOOP;
      END LOOP;
    END;
    $$;


--
-- Name: insert_abstract_trip1(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_abstract_trip1(m integer, n integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    DECLARE j integer;
    DECLARE k integer;
    BEGIN
      FOR i in 1..20 LOOP
	FOR j in m/5..n/5-2 LOOP
		
			insert into abstract_trip(category_id, start_point, end_point) values(i, m, 5*j+4);
		
	END LOOP;
      END LOOP;
    END;
    $$;


--
-- Name: insert_map2(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_map2(m integer, n integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    
    BEGIN
      
	INSERT INTO map2(address) select address from map1 where id between m and n;
      
    END;
    $$;


--
-- Name: nearest_point(double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION nearest_point(lat double precision, lon double precision) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 input_point geometry(Point,4269);
 results integer;
begin
 input_point = st_setsrid(st_makePoint(lon, lat), 4269);
 select location_id into results from location
  where st_dwithin(input_point::geography, point::geography, 100)
  order by st_distance(input_point, point)  limit 1;
 return results;
end
$$;


--
-- Name: pgr_dijkstra_fromatob(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pgr_dijkstra_fromatob(x1 double precision, y1 double precision, x2 double precision, y2 double precision, OUT seq integer, OUT abstract_trip_id integer, OUT name text, OUT heading double precision, OUT cost double precision, OUT geom geometry) RETURNS SETOF record
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
        sql     text;
        rec     record;
        source_val	integer;
        target_val	integer;
        point	integer;
        start_point record;
        end_point record;        
BEGIN
	-- Find nearest node in line
	EXECUTE 'SELECT point FROM location WHERE ST_DWithin(ST_GeometryFromText(''POINT(' 
			|| x1 || ' ' || y1 || ')'',4326)::geography, point::geography, 100) LIMIT 1' INTO start_point;
	SELECT source  into source_val FROM ways WHERE start_point.point = ST_Startpoint(the_geom);
	
	EXECUTE 'SELECT point FROM location WHERE ST_DWithin(ST_GeometryFromText(''POINT(' 
			|| x2 || ' ' || y2 || ')'',4326)::geography, point::geography, 100) LIMIT 1' INTO end_point;
	SELECT target into target_val FROM ways WHERE end_point.point = ST_EndPoint(the_geom);	

	-- Shortest path query (TODO: limit extent by BBOX) 
        seq := 0;
        sql := 'SELECT abstract_trip_id, the_geom, name, cost, source, target, 
				ST_Reverse(the_geom) AS flip_geom FROM ' ||
                        'pgr_dijkstra(''SELECT abstract_trip_id as id, source::int, target::int, '
                                        || 'length::float AS cost FROM ways'', '
                                        || source_val || ', ' || target_val
                                        || ' , false, false), ways WHERE id2 = abstract_trip_id ORDER BY seq';

	-- Remember start point
        point := source_val;

        FOR rec IN EXECUTE sql
        LOOP
		-- Flip geometry (if required)
		IF ( point != rec.source ) THEN
			rec.the_geom := rec.flip_geom;
			point := rec.source;
		ELSE
			point := rec.target;
		END IF;

		-- Calculate heading (simplified)
		EXECUTE 'SELECT degrees( ST_Azimuth( 
				ST_StartPoint(''' || rec.the_geom::text || '''),
				ST_EndPoint(''' || rec.the_geom::text || ''') ) )' 
			INTO heading;

		-- Return record
                seq              := seq + 1;
                abstract_trip_id := rec.abstract_trip_id;
                name             := rec.name;
                cost             := rec.cost;
                geom             := rec.the_geom;
                RETURN NEXT;
        END LOOP;
        RETURN;
END;
$$;


--
-- Name: pgr_dijkstra_fromatob(character varying, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pgr_dijkstra_fromatob(tbl character varying, x1 double precision, y1 double precision, x2 double precision, y2 double precision, OUT seq integer, OUT gid integer, OUT name text, OUT heading double precision, OUT cost double precision, OUT geom geometry) RETURNS SETOF record
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
        sql     text;
        rec     record;
        source_val	integer;
        target_val	integer;
        point	integer;
        start_point record;
        end_point record;        
BEGIN
	-- Find nearest node in line
	EXECUTE 'SELECT point FROM location WHERE ST_DWithin(ST_GeometryFromText(''POINT(' 
			|| x1 || ' ' || y1 || ')'',4326)::geography, point::geography, 100) LIMIT 1' INTO start_point;
	SELECT source  into source_val FROM ways WHERE start_point.point = ST_Startpoint(the_geom);
	
	EXECUTE 'SELECT point FROM location WHERE ST_DWithin(ST_GeometryFromText(''POINT(' 
			|| x2 || ' ' || y2 || ')'',4326)::geography, point::geography, 100) LIMIT 1' INTO end_point;
	SELECT target into target_val FROM ways WHERE end_point.point = ST_EndPoint(the_geom);	

	-- Shortest path query (TODO: limit extent by BBOX) 
        seq := 0;
        sql := 'SELECT abstract_trip_id, the_geom, name, cost, source, target, 
				ST_Reverse(the_geom) AS flip_geom FROM ' ||
                        'pgr_dijkstra(''SELECT abstract_trip_id as id, source::int, target::int, '
                                        || 'length::float AS cost FROM '
                                        || quote_ident(tbl) || ''', '
                                        || source_val || ', ' || target_val
                                        || ' , false, false), '
                                || quote_ident(tbl) || ' WHERE id2 = abstract_trip_id ORDER BY seq';

	-- Remember start point
        point := source_val;

        FOR rec IN EXECUTE sql
        LOOP
		-- Flip geometry (if required)
		IF ( point != rec.source ) THEN
			rec.the_geom := rec.flip_geom;
			point := rec.source;
		ELSE
			point := rec.target;
		END IF;

		-- Calculate heading (simplified)
		EXECUTE 'SELECT degrees( ST_Azimuth( 
				ST_StartPoint(''' || rec.the_geom::text || '''),
				ST_EndPoint(''' || rec.the_geom::text || ''') ) )' 
			INTO heading;

		-- Return record
                seq     := seq + 1;
                gid     := rec.abstract_trip_id;
                name    := rec.name;
                cost    := rec.cost;
                geom    := rec.the_geom;
                RETURN NEXT;
        END LOOP;
        RETURN;
END;
$$;


--
-- Name: settime(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION settime(id integer, speed integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    BEGIN
      UPDATE abstract_trip SET duration = (( ''||2 * cast(getDistance(id)*3600/(speed * 1000) as bigint)||' seconds')::interval::time without time zone) where abstract_trip_id = id;
    END;
    $$;


--
-- Name: update_location(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_location() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE numb int[];
DECLARE n int;
DECLARE i int;
BEGIN
	numb = (SELECT ARRAY(SELECT location_id FROM location WHERE longitude is not null));
	n = (SELECT COUNT(*) FROM location WHERE longitude is not null);
	FOR i in 0..n-1 LOOP
		UPDATE location SET point =  (ST_SetSRID(ST_MakePoint((SELECT longitude FROM location WHERE location_id = numb[i]),
								     (SELECT latitude FROM location WHERE location_id = numb[i])), 4269)) 
		WHERE location_id = numb[i];
	END LOOP;
END;
$$;


--
-- Name: updatetime(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION updatetime() RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    DECLARE j integer;
    BEGIN
      FOR i in 1..10 LOOP
	CASE
	WHEN i = 1 THEN FOR j in 661..668 LOOP 
		PERFORM setTime(j, 60);
		END LOOP;
	WHEN i = 2 THEN FOR j in 669..676 LOOP 
		PERFORM setTime(j, 57);
		END LOOP;
	WHEN i = 3 THEN FOR j in 677..684 LOOP 
		PERFORM setTime(j, 55);
		END LOOP;
	WHEN i = 4 THEN FOR j in 685..692 LOOP 
		PERFORM setTime(j, 52);
		END LOOP;
	WHEN i = 5 THEN FOR j in 693..700 LOOP 
		PERFORM setTime(j, 50);
		END LOOP;
	WHEN i = 6 THEN FOR j in 701..708 LOOP 
		PERFORM setTime(j, 48);
		END LOOP;
	WHEN i = 7 THEN FOR j in 709..716 LOOP 
		PERFORM setTime(j, 45);
		END LOOP;
	WHEN i = 8 THEN FOR j in 717..724 LOOP 
		PERFORM setTime(j, 42);
		END LOOP;
	WHEN i = 9 THEN FOR j in 725..732 LOOP 
		PERFORM setTime(j, 40);
		END LOOP;
	ELSE FOR j in 733..740 LOOP 
		PERFORM setTime(j, 37);
		END LOOP;
	END CASE;
      END LOOP;
    END;
    $$;


--
-- Name: updatetime(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION updatetime(m integer, n integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE i integer;
    BEGIN
      FOR i in m..n LOOP
	CASE
	WHEN (i % 10) = 1 THEN PERFORM setTime(i, 60);
	WHEN (i % 10) = 2 THEN PERFORM setTime(i, 35);
	WHEN (i % 10) = 3 THEN PERFORM setTime(i, 37);
	WHEN (i % 10) = 4 THEN PERFORM setTime(i, 40);
	WHEN (i % 10) = 5 THEN PERFORM setTime(i, 42);
	WHEN (i % 10) = 6 THEN PERFORM setTime(i, 45);
	WHEN (i % 10) = 7 THEN PERFORM setTime(i, 47);
	WHEN (i % 10) = 8 THEN PERFORM setTime(i, 50);
	WHEN (i % 10) = 9 THEN PERFORM setTime(i, 52);
	ELSE PERFORM setTime(i, 55);
	END CASE;
      END LOOP;
    END;
    $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abstract_trip; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE abstract_trip (
    abstract_trip_id integer NOT NULL,
    category_id integer,
    start_point integer,
    end_point integer,
    duration time without time zone,
    estimate_cost double precision,
    is_persistence boolean
);


--
-- Name: abstract_trip_ab_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE abstract_trip_ab_trip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abstract_trip_ab_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE abstract_trip_ab_trip_id_seq OWNED BY abstract_trip.abstract_trip_id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customer (
    customer_id integer NOT NULL,
    name character varying(60),
    address character varying(60),
    postcode character(10),
    email character varying(60),
    user_id integer,
    tel character varying(20)
);


--
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customer_customer_id_seq OWNED BY customer.customer_id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoices (
    invoice_id integer NOT NULL,
    supplier_id integer,
    vehicle_id integer,
    schedule_id integer,
    request_id integer,
    offer_price real,
    status character varying(15),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    message character varying(500)
);


--
-- Name: invoices_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoices_invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoices_invoice_id_seq OWNED BY invoices.invoice_id;


--
-- Name: location; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE location (
    location_id integer NOT NULL,
    radius real,
    location_type smallint,
    country character varying(30),
    city character varying(30),
    street character varying(30),
    address character varying(150),
    point geometry(Point,4269),
    longitude double precision,
    latitude double precision
);


--
-- Name: location_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE location_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE location_location_id_seq OWNED BY location.location_id;


--
-- Name: map2; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE map2 (
    id integer NOT NULL,
    latitude double precision,
    longitude double precision,
    address character varying(120) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: map2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE map2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: map2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE map2_id_seq OWNED BY map2.id;


--
-- Name: maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE maps (
    id integer NOT NULL,
    latitude double precision,
    longitude double precision,
    address character varying(120),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE maps_id_seq OWNED BY maps.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    notification_id integer NOT NULL,
    message character varying,
    targetable_id bigint,
    targetable_type character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    user_id bigint,
    level character varying(10),
    is_read boolean
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_notification_id_seq OWNED BY notifications.notification_id;


--
-- Name: properties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE properties (
    property_id integer NOT NULL,
    name character varying(60),
    unit character(5)
);


--
-- Name: request; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE request (
    request_id integer NOT NULL,
    customer_id integer,
    weight real,
    goods_type smallint,
    height real,
    length real,
    capacity real,
    other_description character varying(60),
    start_point bigint,
    end_point bigint,
    status character varying(15),
    category_id integer,
    "time" timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    start_point_lat numeric,
    start_point_long numeric,
    end_point_lat numeric,
    end_point_long numeric,
    distance_estimate integer
);


--
-- Name: request_request_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE request_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE request_request_id_seq OWNED BY request.request_id;


--
-- Name: schedule; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schedule (
    schedule_id integer NOT NULL,
    estimate_time time without time zone,
    request_id integer,
    level character varying(15),
    abstract_trips text,
    status character varying(15),
    route geometry(MultiLineString,4269)
);


--
-- Name: schedule_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schedule_schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schedule_schedule_id_seq OWNED BY schedule.schedule_id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: supplier; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE supplier (
    supplier_id integer NOT NULL,
    name character varying(60),
    address character varying(60),
    tel bigint,
    email character varying(60),
    user_id integer
);


--
-- Name: supplier_s_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE supplier_s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supplier_s_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE supplier_s_id_seq OWNED BY supplier.supplier_id;


--
-- Name: trip; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trip (
    trip_id bigint NOT NULL,
    vehicle_id integer,
    abstract_trip_id bigint,
    schedule_id integer,
    sequent smallint,
    depature_time timestamp with time zone
);


--
-- Name: trip_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trip_trip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trip_trip_id_seq OWNED BY trip.trip_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: v_category_properties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE v_category_properties (
    property_id integer NOT NULL,
    category_id integer NOT NULL,
    value real
);


--
-- Name: vehicle; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vehicle (
    vehicle_id integer NOT NULL,
    vehicle_number character varying(30) NOT NULL,
    cost_per_km real,
    point geometry(Point,4269),
    category_id bigint,
    s_id integer,
    available boolean,
    image character varying(60)
);


--
-- Name: vehicle_category; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vehicle_category (
    id integer NOT NULL,
    name character varying(60),
    description character varying(60),
    weight real,
    height real,
    length real,
    capacity real
);


--
-- Name: vehicle_category_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vehicle_category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_category_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vehicle_category_category_id_seq OWNED BY vehicle_category.id;


--
-- Name: vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vehicle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vehicle_id_seq OWNED BY vehicle.vehicle_id;


--
-- Name: ways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ways (
    abstract_trip_id integer,
    class_id integer NOT NULL,
    length double precision,
    name text,
    x1 double precision,
    y1 double precision,
    x2 double precision,
    y2 double precision,
    reverse_cost double precision,
    rule text,
    to_cost double precision,
    maxspeed_forward integer,
    maxspeed_backward integer,
    osm_id bigint,
    priority double precision DEFAULT 1,
    the_geom geometry(LineString,4269),
    source integer,
    target integer
);


--
-- Name: abstract_trip_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_trip ALTER COLUMN abstract_trip_id SET DEFAULT nextval('abstract_trip_ab_trip_id_seq'::regclass);


--
-- Name: customer_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customer ALTER COLUMN customer_id SET DEFAULT nextval('customer_customer_id_seq'::regclass);


--
-- Name: invoice_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices ALTER COLUMN invoice_id SET DEFAULT nextval('invoices_invoice_id_seq'::regclass);


--
-- Name: location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY location ALTER COLUMN location_id SET DEFAULT nextval('location_location_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY map2 ALTER COLUMN id SET DEFAULT nextval('map2_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY maps ALTER COLUMN id SET DEFAULT nextval('maps_id_seq'::regclass);


--
-- Name: notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN notification_id SET DEFAULT nextval('notifications_notification_id_seq'::regclass);


--
-- Name: request_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY request ALTER COLUMN request_id SET DEFAULT nextval('request_request_id_seq'::regclass);


--
-- Name: schedule_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule ALTER COLUMN schedule_id SET DEFAULT nextval('schedule_schedule_id_seq'::regclass);


--
-- Name: supplier_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY supplier ALTER COLUMN supplier_id SET DEFAULT nextval('supplier_s_id_seq'::regclass);


--
-- Name: trip_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trip ALTER COLUMN trip_id SET DEFAULT nextval('trip_trip_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: vehicle_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vehicle ALTER COLUMN vehicle_id SET DEFAULT nextval('vehicle_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vehicle_category ALTER COLUMN id SET DEFAULT nextval('vehicle_category_category_id_seq'::regclass);


--
-- Name: abstract_trip_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY abstract_trip
    ADD CONSTRAINT abstract_trip_pkey PRIMARY KEY (abstract_trip_id);


--
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- Name: invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (invoice_id);


--
-- Name: location_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY location
    ADD CONSTRAINT location_pkey PRIMARY KEY (location_id);


--
-- Name: maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY maps
    ADD CONSTRAINT maps_pkey PRIMARY KEY (id);


--
-- Name: maps_pkey2; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY map2
    ADD CONSTRAINT maps_pkey2 PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (property_id);


--
-- Name: request_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY request
    ADD CONSTRAINT request_pkey PRIMARY KEY (request_id);


--
-- Name: schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT schedule_pkey PRIMARY KEY (schedule_id);


--
-- Name: supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (supplier_id);


--
-- Name: trip_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trip
    ADD CONSTRAINT trip_pkey PRIMARY KEY (trip_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: v_category_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY v_category_properties
    ADD CONSTRAINT v_category_properties_pkey PRIMARY KEY (property_id, category_id);


--
-- Name: vehicle_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vehicle_category
    ADD CONSTRAINT vehicle_category_pkey PRIMARY KEY (id);


--
-- Name: vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicle_id);


--
-- Name: vehicle_vehicle_number_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vehicle
    ADD CONSTRAINT vehicle_vehicle_number_key UNIQUE (vehicle_number);


--
-- Name: geom_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX geom_idx ON ways USING gist (the_geom);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: source_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX source_idx ON ways USING btree (source);


--
-- Name: target_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX target_idx ON ways USING btree (target);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: ways_gid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ways_gid_idx ON ways USING btree (abstract_trip_id);


--
-- Name: check_point; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_point BEFORE INSERT OR UPDATE ON trip FOR EACH ROW EXECUTE PROCEDURE check_point();


--
-- Name: create_new_way; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_new_way AFTER INSERT OR UPDATE ON abstract_trip FOR EACH ROW EXECUTE PROCEDURE create_new_way();


--
-- Name: abstract_trip_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_trip
    ADD CONSTRAINT abstract_trip_category_id_fkey FOREIGN KEY (category_id) REFERENCES vehicle_category(id);


--
-- Name: abstract_trip_end_point_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_trip
    ADD CONSTRAINT abstract_trip_end_point_fkey FOREIGN KEY (end_point) REFERENCES location(location_id);


--
-- Name: abstract_trip_start_point_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_trip
    ADD CONSTRAINT abstract_trip_start_point_fkey FOREIGN KEY (start_point) REFERENCES location(location_id);


--
-- Name: invoice_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoice_request_id_fkey FOREIGN KEY (request_id) REFERENCES request(request_id);


--
-- Name: invoice_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoice_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id);


--
-- Name: invoice_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoice_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id);


--
-- Name: invoice_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoice_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id);


--
-- Name: request_cus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY request
    ADD CONSTRAINT request_cus_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);


--
-- Name: schedule_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT schedule_request_id_fkey FOREIGN KEY (request_id) REFERENCES request(request_id);


--
-- Name: trip_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trip
    ADD CONSTRAINT trip_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id);


--
-- Name: v_category_properties_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY v_category_properties
    ADD CONSTRAINT v_category_properties_property_id_fkey FOREIGN KEY (property_id) REFERENCES properties(property_id);


--
-- Name: v_category_properties_v_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY v_category_properties
    ADD CONSTRAINT v_category_properties_v_category_id_fkey FOREIGN KEY (category_id) REFERENCES vehicle_category(id);


--
-- Name: vehicle_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vehicle
    ADD CONSTRAINT vehicle_category_id_fkey FOREIGN KEY (category_id) REFERENCES vehicle_category(id);


--
-- Name: vehicle_s_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vehicle
    ADD CONSTRAINT vehicle_s_id_fkey FOREIGN KEY (s_id) REFERENCES supplier(supplier_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20151105023430');

INSERT INTO schema_migrations (version) VALUES ('20151105023751');

INSERT INTO schema_migrations (version) VALUES ('20151105024928');

INSERT INTO schema_migrations (version) VALUES ('20151105025317');

INSERT INTO schema_migrations (version) VALUES ('20160328132848');

