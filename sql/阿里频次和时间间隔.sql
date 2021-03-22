-- 频次

-- 频次 改时间直接跑
select vendor "媒体",
        spot "点位",
       total_imp "曝光",
       total_uv UV,
       imp100plus "曝光100+",
       imp100plus * 1.0000 / total_imp "曝光100+占比",
       uv100plus "UV100+",
       uv100plus * 1.0000 / total_uv "UV100+占比",
       imp50plus "曝光50+",
       imp50plus * 1.0000 / total_imp "曝光50+占比",
       uv50plus "UV50+",
       uv50plus * 1.0000 / total_uv "UV50+占比",
       imp20plus "曝光20+",
       imp20plus * 1.0000 / total_imp "曝光20+占比",
       uv20plus "UV20+",
       uv20plus * 1.0000 / total_uv "UV20+占比",
       imp10plus "曝光10+",
       imp10plus * 1.0000 / total_imp "曝光10+占比",
       uv10plus "UV10+",
       uv10plus * 1.0000 / total_uv "UV10+占比"

from (
         select vendor,
                 spot,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
                sum(if(pv > 100, uv * pv, 0)) imp100plus,
                sum(if(pv > 100, uv, 0))      uv100plus,
                sum(if(pv > 50, uv * pv, 0))  imp50plus,
                sum(if(pv > 50, uv, 0))       uv50plus,
                sum(if(pv > 20, uv * pv, 0))  imp20plus,
                sum(if(pv > 20, uv, 0))       uv20plus,
                sum(if(pv > 10, uv * pv, 0))  imp10plus,
                sum(if(pv > 10, uv, 0))       uv10plus

         from (
                  select vendor,
                          spot,
                         pv,
                         count(distinct ext_user_id) uv

                  from (
                           select upper(b.vendor) vendor, b.spot,a.ext_user_id, count(distinct ext_request_id) as pv
                           from dwd.d_ad_ftx_impression_data a

                                    join
                                (
                                    select o.id, sp.spot, sp.vendor
                                    from u6rds.ftx."order" o
                                join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
                                    on o.parent_id=sp.id
                                    where sp.type = 'porder'
                                    group by 1, 2, 3
                                ) b
                                on a.ext_order_id = b.id
                           where a.thisdate = '2021-01-25'
                           group by 1, 2,3
                       ) t
                  group by 1, 2,3
              ) c
         group by 1,2
     ) d

order by 1

-- 频次 下拉二楼/ICON ip/ext_user_id 设备频次和ip频次 更改日期 点击曝光更改表
select -- vendor "媒体",
       spot_id,
       total_imp                       "曝光",
       total_uv                        UV,
       imp10                           "曝光10次以内",
       imp10 * 1.0000 / total_imp      "曝光10次以内占比",
       uv10                            "UV10以内",
       uv10 * 1.0000 / total_uv        "UV10以内占比",
       imp10plus                       "曝光10+",
       imp10plus * 1.0000 / total_imp  "曝光10+占比",
       uv10plus                        "UV10+",
       uv10plus * 1.0000 / total_uv    "UV10+占比",
       imp20plus                       "曝光20+",
       imp20plus * 1.0000 / total_imp  "曝光20+占比",
       uv20plus                        "UV20+",
       uv20plus * 1.0000 / total_uv    "UV20+占比",
       imp50plus                       "曝光50+",
       imp50plus * 1.0000 / total_imp  "曝光50+占比",
       uv50plus                        "UV50+",
       uv50plus * 1.0000 / total_uv    "UV50+占比",
       imp100plus                      "曝光100+",
       imp100plus * 1.0000 / total_imp "曝光100+占比",
       uv100plus                       "UV100+",
       uv100plus * 1.0000 / total_uv   "UV100+占比",
       imp200plus                      "曝光200+",
       imp200plus * 1.0000 / total_imp "曝光200+占比",
       uv200plus                       "UV200+",
       uv200plus * 1.0000 / total_uv   "UV200+占比",
       imp500plus                      "曝光500+",
       imp500plus * 1.0000 / total_imp "曝光500+占比",
       uv500plus                       "UV500+",
       uv500plus * 1.0000 / total_uv   "UV500+占比"
from (
         select -- vendor,
                spot_id,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
                sum(if(pv > 500, uv * pv, 0)) imp500plus,
                sum(if(pv > 500, uv, 0))      uv500plus,
                sum(if(pv > 200, uv * pv, 0)) imp200plus,
                sum(if(pv > 200, uv, 0))      uv200plus,
                sum(if(pv > 100, uv * pv, 0)) imp100plus,
                sum(if(pv > 100, uv, 0))      uv100plus,
                sum(if(pv > 50, uv * pv, 0))  imp50plus,
                sum(if(pv > 50, uv, 0))       uv50plus,
                sum(if(pv > 20, uv * pv, 0))  imp20plus,
                sum(if(pv > 20, uv, 0))       uv20plus,
                sum(if(pv > 10, uv * pv, 0))  imp10plus,
                sum(if(pv > 10, uv, 0))       uv10plus,
                sum(if(pv <= 10, uv, 0))      uv10,
                sum(if(pv <= 10, uv * pv, 0)) imp10

         from (
                  select -- vendor,
                         spot_id,
                         pv,
                         count(distinct ip) uv

                  from (
                           select b.spot_id,
                                  a.ip,
                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_clicklog_day a
                                    join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34623,34624)

                                --          join
                                --      (
                                --      select o.id,b.amo_order_id-- , sp.spot , sp.vendor
                                --      from u6rds.ftx."order" o
                                --      join u6rds.ftx.order_detail_amo_order b on o.id=b.order_id
                                --      where b.amo_order_id in (3003,3015,3016,3014,3046,3025)
                                --      group by 1,2
                                --      -- group by 1, 2, 3
                                --      ) b
                                --      on a.ext_order_id = b.id
                                -- left join u6rds.ftx.order_detail_amo_order c
                                -- on a.ext_order_id = c.order_id
                           where a.thisdate = '2021-01-25'
                             and ext_adgroup_id in (select id from u6rds.ad_fancy.ad_group where spot_id in (34623,34624))
                             -- and spot_id =34623

                           group by 1, 2
                       ) t
                  group by 1, 2
              ) c
         group by 1
     ) d
order by 1


-- 频次 开屏 同ICON/下拉二楼 使用方法
select -- vendor "媒体",
       amo_order_id,
       total_imp                       "曝光",
       total_uv                        UV,
       imp10                           "曝光10次以内",
       imp10 * 1.0000 / total_imp      "曝光10次以内占比",
       uv10                            "UV10以内",
       uv10 * 1.0000 / total_uv        "UV10以内占比",
       imp10plus                       "曝光10+",
       imp10plus * 1.0000 / total_imp  "曝光10+占比",
       uv10plus                        "UV10+",
       uv10plus * 1.0000 / total_uv    "UV10+占比",
       imp20plus                       "曝光20+",
       imp20plus * 1.0000 / total_imp  "曝光20+占比",
       uv20plus                        "UV20+",
       uv20plus * 1.0000 / total_uv    "UV20+占比",
       imp50plus                       "曝光50+",
       imp50plus * 1.0000 / total_imp  "曝光50+占比",
       uv50plus                        "UV50+",
       uv50plus * 1.0000 / total_uv    "UV50+占比",
       imp100plus                      "曝光100+",
       imp100plus * 1.0000 / total_imp "曝光100+占比",
       uv100plus                       "UV100+",
       uv100plus * 1.0000 / total_uv   "UV100+占比",
       imp200plus                      "曝光200+",
       imp200plus * 1.0000 / total_imp "曝光200+占比",
       uv200plus                       "UV200+",
       uv200plus * 1.0000 / total_uv   "UV200+占比",
       imp500plus                      "曝光500+",
       imp500plus * 1.0000 / total_imp "曝光500+占比",
       uv500plus                       "UV500+",
       uv500plus * 1.0000 / total_uv   "UV500+占比"
from (
         select -- vendor,
                amo_order_id,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
                sum(if(pv > 500, uv * pv, 0)) imp500plus,
                sum(if(pv > 500, uv, 0))      uv500plus,
                sum(if(pv > 200, uv * pv, 0)) imp200plus,
                sum(if(pv > 200, uv, 0))      uv200plus,
                sum(if(pv > 100, uv * pv, 0)) imp100plus,
                sum(if(pv > 100, uv, 0))      uv100plus,
                sum(if(pv > 50, uv * pv, 0))  imp50plus,
                sum(if(pv > 50, uv, 0))       uv50plus,
                sum(if(pv > 20, uv * pv, 0))  imp20plus,
                sum(if(pv > 20, uv, 0))       uv20plus,
                sum(if(pv > 10, uv * pv, 0))  imp10plus,
                sum(if(pv > 10, uv, 0))       uv10plus,
                sum(if(pv <= 10, uv, 0))      uv10,
                sum(if(pv <= 10, uv * pv, 0)) imp10

         from (
                  select -- vendor,
                         amo_order_id,
                         pv,
                         count(distinct ip) uv

                  from (
                           select b.amo_order_id,
                                  a.ip,

                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_ftx_impression_data a

                                    join
                                (
                                    select o.id, b.amo_order_id-- , sp.spot , sp.vendor
                                    from u6rds.ftx."order" o
                                             join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
                                    where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
                                    group by 1, 2
                                    -- group by 1, 2, 3
                                ) b
                                on a.ext_order_id = b.id
                                    left join u6rds.ftx.order_detail_amo_order c
                                              on a.ext_order_id = c.order_id
                           where a.thisdate = '2021-01-25'
                                 -- and spot_id =34623

                           group by 1, 2
                       ) t
                  group by 1, 2
              ) c
         group by 1
     ) d
order by 1

-- 时间间隔 ICON/下拉二楼 根据要求调节间隔 默认 0-30，30-60，60-120，120+ 更改点击曝光表时要更改时间名称 time/timestamp
select id, s30, 1.0000*s30/t, s60-s30, 1.0000*(s60-s30)/t, s120-s60, 1.0000*(s120-s60)/t, s121, 1.0000*s121/t,t
from (
         select spot_id             id,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
--                         else 0 end) s5,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
--                         else 0 end) s10,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 120 then 1
                        else 0 end) s120,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) > 120 then 1
                        else 0 end) s121,
                sum(imp)            t
         from (
                  select spot_id, time
                          , lag(time, 1, cast('1970-01-01 00:00:00' as timestamp )) over(partition by spot_id, ext_user_id order by time) as p_time
                          , lead(time, 1, cast('2099-12-31 23:59:59' as timestamp )) over(partition by spot_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select b.spot_id, ext_user_id,ext_ad_id
                      -- timestamp imp, time click
                          , cast (replace(timestamp , '_', ' ') as timestamp) as time
                      -- from dwd.d_ad_clicklog_day a
                       from dwd.d_ad_impression a
                      join u6rds.ad_fancy.ad_group b on b.id=a.ext_adgroup_id and b.spot_id = 34624
                      where thisdate='2021-01-25'
                      -- imp
                      -- and hour ='13'
                      -- click
                      -- and time >= '2021-01-20 19:00:00'
                      -- and time < '2021-01-20 20:00:00'
                       and ext_ad_id <> 460004
                      ) a
              ) b
         group by 1
         order by 1
     )
order by 1



-- 时间间隔 开屏 根据要求调节间隔 默认 0-30，30-60，60-120，120+ 更改点击曝光表时要更改时间名称 time/timestamp
select id, s30, 1.0000*s30/t, s60-s30, 1.0000*(s60-s30)/t, s120-s60, 1.0000*(s120-s60)/t, s121, 1.0000*s121/t,t
from (
         select amo_order_id             id,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
--                         else 0 end) s5,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
--                         else 0 end) s10,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) <= 120 then 1
                        else 0 end) s120,
                sum(case
                        when if(date_diff('second', time, a_time)>date_diff('second', p_time, time),date_diff('second', p_time, time),date_diff('second', time, a_time)) > 120 then 1
                        else 0 end) s121,
                sum(imp)            t
         from (
                  select amo_order_id, time
                          , lag(time, 1, cast('1970-01-01 00:00:00' as timestamp )) over(partition by amo_order_id, ext_user_id order by time) as p_time
                          , lead(time, 1, cast('2099-12-31 23:59:59' as timestamp )) over(partition by amo_order_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select amo_order_id, ext_user_id
                      -- timestamp imp, time click
                          , cast (replace(timestamp, '_', ' ') as timestamp) as time
                       from dwd.d_ad_ftx_impression_data a
                      -- from dwd.d_ad_ftx_click_data a
                      join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
                      from u6rds.ftx."order" o
                      join u6rds.ftx.order_detail_amo_order b on o.id=b.order_id
                      where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
                      group by 1, 2) b on a.ext_order_id=b.id
                      where thisdate='2021-01-25'
                      -- imp
                      -- and hour = '19'
                      -- click
                      -- and time >= '2021-01-20 19:00:00'
                      -- and time < '2021-01-20 20:00:00'
                      ) a
              ) b
         group by 1
         order by 1
     )
order by 1

-- 异常IP 和 异常设备
select  upper(b.vendor)                   vendor,
     ext_user_id id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_ftx_click_data a

         join
     (
         select o.id , sp.spot, sp.vendor
         from u6rds.ftx."order" o
               join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
               on o.parent_id=sp.id
         group by 1, 2, 3
     ) b
     on a.ext_order_id = b.id
where a.thisdate = '2021-01-25'
group by 1,2
having count(distinct ext_request_id) > 500
union all
select  upper(b.vendor)                   vendor,
       ip id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_ftx_click_data a

         join
     (
         select o.id , sp.spot, sp.vendor
         from u6rds.ftx."order" o
               join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
               on o.parent_id=sp.id
         group by 1, 2, 3
     ) b
     on a.ext_order_id = b.id
where a.thisdate = '2021-01-25'
group by 1,2
having count(distinct ext_request_id) > 500
order by 2 desc;

-- referer
select count(ext_request_id) "总量", sum(if(referer is null or referer = '', 0, 1)) "异常"
-- site_refer
from dwd.d_ad_ftx_click_data
-- d_ad_ftx_request
where thisdate = '2021-01-25'
  and ext_ad_id = 462652
-- and source_id = 244



select distinct referer
from dwd.d_ad_ftx_click_data
where thisdate = '2021-01-25'
  and ext_order_id = 44260
--   and "timestamp" < '2021-01-20 15:00:00'
  and referer is not null
  and referer <> ''

-- anonymous_ua
select count(ext_request_id) "总量", sum(if(anonymous_ua = 0, 1, 0)) "异常"
from dwd.d_ad_ftx_click_data
where thisdate = '2021-01-25'
  and ext_ad_id = 462652

select user_agent, anonymous_ua
from dwd.d_ad_ftx_click_data
where thisdate = '2021-01-25'
  and ext_ad_id = 462652
  and anonymous_ua = 0

-- 安卓10 必须有 oaid
select count(user_agent) "总量", sum(if(ext_mobile_oaid is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-25'
  and ext_ad_id = 462652
  and user_agent like '%Android 1%'


-- Imei_md5 && oaid  && idfa为空
select count(*)                                                                                           "总量",
       sum(if(ext_mobile_imei_md5 is null and ext_mobile_oaid is null and ext_mobile_idfa is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-25'
  and ext_ad_id = 462652