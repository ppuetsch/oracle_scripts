--------------------------------------------------------------------------------
--
-- File name:   max_write_iops_benchmark_slave.sql
--
-- Version:     1.03 (April 2019)
--
--              Tested with client version SQL*Plus 11.2.0.1 and 12.2.0.1
--              Tested with server versions 11.2.0.4, 12.1.0.2 and 12.2.0.1
--
-- Author:      Randolf Geist
--              http://www.oracle-performance.de
--
-- Purpose:     Perform physical read and write I/O mostly
--              This is the slave script that gets started by "max_write_iops_benchmark_harness.sql" as many times as requested
--
--              Parameters: The "instance" of the slave, the testtype (currently unused) and the time to execute in seconds
--
-- Prereq:      Objects created by "max_write_iops_benchmark_harness.sql"
--
--------------------------------------------------------------------------------

set linesize 200 echo on timing on trimspool on tab off define "&" verify on

define tabname = &1

define thread_id = &1

define testtype = &2

define wait_time = "&3 + 10"

exec dbms_application_info.set_action('SQLPWIO&2')

-- This is required from 11.2 on to get the BYPASS_UJVC hint working below
exec dbms_snapshot.set_i_am_a_refresh(true)

declare
  cnt number;
  start_time date;
begin
  start_time := sysdate;
  cnt := 0;
  loop
    update (
    select /*+
              bypass_ujvc
              leading(t_o)
              use_nl(t_i)
              index(t_o)
              index(t_i)
          */
          t_i.n
          --into n
    from
          t_o
        , t_i&tabname t_i
    where
          t_o.id_fk = t_i.id
    )
    set n = n + decode(mod(n, 2), 0, -1, 1)
    ;
    cnt := cnt + 1;
    --if mod(cnt, 100) = 0 then
    exit when (sysdate - start_time) * 86400 >= &wait_time;
    --end if;
    if cnt > 100 then
      commit write batch nowait;
      --exit when (sysdate - start_time) * 86400 >= &wait_time;
      cnt := 0;
    end if;
    -- insert into timings(testtype, thread_id, ts) values ('&testtype', &thread_id, systimestamp);
  end loop;
  commit write batch nowait;
end;
/

exec dbms_snapshot.set_i_am_a_refresh(false)

undefine tabname
undefine thread_id
undefine testtype
undefine wait_time

exit
