select referer, anonymous_ua, ext_mobile_idfa, ext_mobile_imei_md5, ext_mobile_oaid
from dwd.d_ad_impression
where thisdate = '2021-01-14'
  and ext_ad_id = 460137 limit 100

-- referer
select count(referer) "总量", sum(if(referer is null or referer = '', 0, 1)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260

select distinct referer
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260
--   and "timestamp" < '2021-01-20 15:00:00'
  and referer is not null
  and referer <> ''

-- anonymous_ua
select count(anonymous_ua) "总量", sum(if(anonymous_ua = 0, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260

select user_agent, anonymous_ua
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260
  and anonymous_ua = 0

-- 安卓10 必须有 oaid
select count(user_agent) "总量", sum(if(ext_mobile_oaid is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260
  and user_agent like '%Android 1%'


-- Imei_md5 && oaid  && idfa为空
select count(*)                                                                                           "总量",
       sum(if(ext_mobile_imei_md5 is null and ext_mobile_oaid is null and ext_mobile_idfa is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data
where thisdate = '2021-01-20'
  and ext_order_id = 44260
-- 父订单----------------------------------------------------
select -- vendor "媒体",
       -- spot "点位",
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
       uv100plus * 1.0000 / total_uv   "UV100+占比"
from (
         select -- vendor,
                -- spot,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
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
                         -- spot,
                         pv,
                         count(distinct ext_user_id) uv

                  from (
                           select -- upper(b.vendor) vendor,
                                  a.ext_user_id,
                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_ftx_impression_data a

                                    join
                                (
                                    select o.id -- , sp.spot, sp.vendor
                                    from u6rds.ftx."order" o
                                         -- join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
                                         -- on o.parent_id=sp.id
                                         -- where o.parent_id = 44260
                                         -- order id
                                    where o.id = 44260
                                    -- group by 1, 2, 3
                                ) b
                                on a.ext_order_id = b.id
                           where a.thisdate = '2021-01-20'
                           group by 1
                       ) t
                  group by 1
              ) c
     ) d


-- 异常IP 和 异常设备
select  upper(b.vendor)                   vendor,
       ip,
--        a.ext_user_id,
       count(distinct ip) as pv
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
--   and vendor = '韩剧TV'
group by 1,2
having count(distinct ext_request_id) > 500
order by 2 desc;
-- 计划id----------------------------------------------------
select -- vendor "媒体",
       -- spot "点位",
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
       uv100plus * 1.0000 / total_uv   "UV100+占比"
from (
         select -- vendor,
                -- spot,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
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
                         -- spot,
                         pv,
                         count(distinct ext_user_id) uv

                  from (
                           select -- upper(b.vendor) vendor,
                                  a.ext_user_id,
                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_impression a

                                    join
                                (
                                    select ad.id
                                    from u6rds.ad_fancy.ad
                                             join u6rds.ad_fancy.ad_group on ad.ad_group_id = ad_group.id
                                             join u6rds.ad_fancy.spot sp on sp.id = ad_group.spot_id
                                    where ad_group.campaign_id = 46541
                                    group by 1
                                ) b
                                on a.ext_ad_id = b.id
                           where a.thisdate = '2021-01-20'
                           group by 1
                       ) t
                  group by 1
              ) c
     ) d


-- 异常IP 和 异常设备
select -- upper(b.vendor)                   vendor,
       ext_user_id,
--        a.ext_user_id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_impression a

         join
     (
         select o.id -- , sp.spot, sp.vendor
         from u6rds.ftx."order" o
         -- join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
         -- on o.parent_id=sp.id
         -- group by 1, 2, 3
     ) b
     on a.ext_order_id = b.id
where a.thisdate = '2021-01-20'
  and spot_id = 34623
group by 1
having count(distinct ext_request_id) > 500
order by 2 desc;
-- ----------------------------------------------------
-- amo----------------------------------------------------
select -- vendor "媒体",
       -- spot "点位",
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
       uv100plus * 1.0000 / total_uv   "UV100+占比"
from (
         select -- vendor,
                -- spot,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
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
                         -- spot,
                         pv,
                         count(distinct ext_user_id) uv

                  from (
                           select -- upper(b.vendor) vendor,
                                  a.ext_user_id,
                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_ftx_impression_data a

                                    join
                                (
                                    select o.id-- , sp.spot , sp.vendor
                                    from u6rds.ftx."order" o


                                    -- group by 1, 2, 3
                                ) b
                                on a.ext_order_id = b.id
                                    left join u6rds.ftx.order_detail_amo_order c
                                              on a.ext_order_id = c.order_id
                           where a.thisdate = '2021-01-20'
                             -- and spot_id =34623

                             and c.amo_order_id in (3014, 3046, 3003)
                           group by 1
                       ) t
                  group by 1
              ) c
     ) d


-- 异常IP 和 异常设备
select -- upper(b.vendor)                   vendor,
       ext_user_id,
--        a.ext_user_id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_ftx_impression_data a

         join
     (
         select o.id -- , sp.spot, sp.vendor
         from u6rds.ftx."order" o
         -- join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
         -- on o.parent_id=sp.id
         -- group by 1, 2, 3
     ) b
     on a.ext_order_id = b.id
         left join u6rds.ftx.order_detail_amo_order c
                   on a.ext_order_id = c.order_id
where a.thisdate = '2021-01-20'
  and c.amo_order_id in (3014, 3046, 3003)
--   and vendor = '韩剧TV'
group by 1
having count(distinct ext_request_id) > 500
order by 2 desc;
-- ----------------------------------------------------
select if(clk_ext_parent_order_id = 41802, '韩剧', 'soul') vendor,
       thisdate,
       case
           when resp_seat_bid_landing_page like '%http://click.tanx%' then 'tanx.com'
           when resp_seat_bid_landing_page like '%https://h5.ele.me%' then 'ele.me'
           when resp_seat_bid_landing_page like '%https://render.alipay%' then 'render.alipay'
           else 'others' end                             url_,
       count(1)
from (
         select clk_ext_parent_order_id, thisdate, resp_seat_bid_landing_page, resp_seat_bid_clk_monitor_urls
         from dws.s_ad_ftx_join
         where thisdate >= '2020-12-05'
           and thisdate <= '2020-12-06'
           and clk_ext_parent_order_id in (41802, 41778)
     ) a
group by 1, 2, 3


-- 5 6
select thisdate,
       if(resp_landing_desc like '%deeplink_universal_url%', 'ios', 'android') os,

       sum(if(replace(resp_landing_desc, '%', '_') like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays_3a_2f_2fplatformapi_2fstartapp_3fappId_3d2018090761255717_26page_3dpages_252Fwebview-redirect_252Fwebview-redirect_253Furl_253Dhttps_253a_252f_252fclick.tanx.com%'
                  or replace(resp_landing_desc, '%', '_') like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages_2Fwebview-redirect_2Fwebview-redirect_3Furl_3Dhttps_3a_2f_2fclick.tanx.com%'
           , 1, 0))                                                            abnormal_alipay,
       sum(if(replace(resp_landing_desc, '%', '_') like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays_3a_2f_2fplatformapi_2fstartapp_3fappId_3d2018090761255717_26page_3dpages_252Fwebview-redirect_252Fwebview-redirect_253Furl_253Dhttps_25253a_25252f_25252fclick.tanx.com%'
                  or replace(resp_landing_desc, '%', '_') like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages_2Fwebview-redirect_2Fwebview-redirect_3Furl_3Dhttps_253a_252f_252fclick.tanx.com%'
           , 1, 0))                                                            normal_alipay,
       sum(if(resp_landing_desc like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays%3a%2f%2fplatformapi%2fstartapp%3fappId%3d2018090761255717%26page%3dpages%252Fwebview-redirect%252Fwebview-redirect%253Furl%253Dhttps%253a%252f%252fclick.tanx.com%'
                  or resp_landing_desc like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%2Fwebview-redirect%2Fwebview-redirect%3Furl%3Dhttps%3a%2f%2fclick.tanx.com%'
                  or resp_landing_desc like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%2Fwebview-redirect%2Fwebview-redirect%3Furl%3Dhttps%253a%252f%252fclick.tanx.com%'
                  or resp_landing_desc like
                     '%https://render.alipay.com/p/s/ulink?scheme=alipays%3a%2f%2fplatformapi%2fstartapp%3fappId%3d2018090761255717%26page%3dpages%252Fwebview-redirect%252Fwebview-redirect%253Furl%253Dhttps%25253a%25252f%25252fclick.tanx.com%'
           , 1, 0))                                                            total_alipay,
       sum(if(resp_landing_desc like '%https://h5.ele.me%' or
              resp_landing_desc like '%eleme://web?action=ali.open.nav&bootImage=0&source=alimama&appkey=%', 1,
              0))                                                              eleme,

       sum(if(dp_dplink like '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%' or
              dp_dplink like '%render.alipay.com%', 1, 0))                     alipay_dp,
       sum(if(dp_dplink like '%eleme://web?action=ali.open.nav&bootImage=0&source=alimama&appkey=31067914&appName=%' or
              dp_dplink like '%https://h5.ele.me%', 1, 0))                     eleme_dp,
       count(1)

from dws.s_ad_ftx_join
where thisdate >= '2020-12-05'
  and thisdate <= '2020-12-06'
  and clk_ext_ftx_order_id = 41779
group by 1, 2


-- 点击间隔--------------------------------------------------------------------------------
select sum(smin)                                  "30s内pv",
       sum(case when smin > 0 then 1 else 0 end)  "30s内uv",
       sum(wmin)                                  "60s内pv",
       sum(case when wmin > 0 then 1 else 0 end)  "60s内uv",
       sum(qmin)                                  "90s内pv",
       sum(case when qmin > 0 then 1 else 0 end)  "90s内uv",
       sum(shmin)                                 "120s内pv",
       sum(case when shmin > 0 then 1 else 0 end) "120s内uv",
       sum(total)                                 "pv",
       count(distinct uid)                        uv
from (
         select uid
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 30 then 1
                        else 0 end) as smin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 60 then 1
                        else 0 end) as wmin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 90 then 1
                        else 0 end) as qmin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 120 then 1
                        else 0 end) as shmin
              , sum(1)                 total
         from (
                  select a.ext_user_id uid, timestamp t1, lead(timestamp) over(partition by ext_user_id order by timestamp) t2
                  from dwd.d_ad_clicklog_day a
--                       join
--                       (
--                       select o.id -- , sp.spot, sp.vendor
--                       from u6rds.ftx."order" o
--                       where o.id = 44260
--                       ) b
--                   on a.ext_order_id = b.id
                  where a.thisdate = '2021-01-20'
                    and ext_order_id = 3023
              )
         group by 1
     )

--    -----------------------
select sum(smin)                                  "30s内pv",
       sum(case when smin > 0 then 1 else 0 end)  "30s内uv",
       sum(wmin)                                  "60s内pv",
       sum(case when wmin > 0 then 1 else 0 end)  "60s内uv",
       sum(qmin)                                  "90s内pv",
       sum(case when qmin > 0 then 1 else 0 end)  "90s内uv",
       sum(shmin)                                 "120s内pv",
       sum(case when shmin > 0 then 1 else 0 end) "120s内uv",
       sum(total)                                 "pv",
       count(distinct uid)                        uv
from (
         select uid
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 30 then 1
                        else 0 end) as smin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 60 then 1
                        else 0 end) as wmin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 90 then 1
                        else 0 end) as qmin
              , sum(case
                        when date_diff('second', cast(t1 as timestamp), cast(t2 as timestamp)) <= 120 then 1
                        else 0 end) as shmin
              , sum(1)                 total
         from (
                  select a.ext_user_id uid, time t1, lead(time) over(partition by ext_user_id order by time) t2
                  from dwd.d_ad_clicklog_day a
--                       join
--                       (
--                       select o.id -- , sp.spot, sp.vendor
--                       from u6rds.ftx."order" o
--                       where o.id = 44260
--                       ) b
--                   on a.ext_order_id = b.id
                  where a.thisdate = '2021-01-20'
                    and ext_order_id = 3023
              )
         group by 1
     )
-- --------------------------------------------------------------------------------
-- hour
select substr(win_ext_timestamp, 12, 2),
       if(resp_landing_desc like '%deeplink_universal_url%', 'ios', 'android') os,

       sum(if(replace(resp_landing_desc, '%', '_') like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays_3a_2f_2fplatformapi_2fstartapp_3fappId_3d2018090761255717_26page_3dpages_252Fwebview-redirect_252Fwebview-redirect_253Furl_253Dhttps_253a_252f_252fclick.tanx.com%'
                  or replace(resp_landing_desc, '%', '_') like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages_2Fwebview-redirect_2Fwebview-redirect_3Furl_3Dhttps_3a_2f_2fclick.tanx.com%'
           , 1, 0))                                                            abnormal_alipay,
       sum(if(replace(resp_landing_desc, '%', '_') like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays_3a_2f_2fplatformapi_2fstartapp_3fappId_3d2018090761255717_26page_3dpages_252Fwebview-redirect_252Fwebview-redirect_253Furl_253Dhttps_25253a_25252f_25252fclick.tanx.com%'
                  or replace(resp_landing_desc, '%', '_') like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages_2Fwebview-redirect_2Fwebview-redirect_3Furl_3Dhttps_253a_252f_252fclick.tanx.com%'
           , 1, 0))                                                            normal_alipay,
       sum(if(resp_landing_desc like
              '%https://render.alipay.com/p/s/ulink?scheme=alipays%3a%2f%2fplatformapi%2fstartapp%3fappId%3d2018090761255717%26page%3dpages%252Fwebview-redirect%252Fwebview-redirect%253Furl%253Dhttps%253a%252f%252fclick.tanx.com%'
                  or resp_landing_desc like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%2Fwebview-redirect%2Fwebview-redirect%3Furl%3Dhttps%3a%2f%2fclick.tanx.com%'
                  or resp_landing_desc like
                     '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%2Fwebview-redirect%2Fwebview-redirect%3Furl%3Dhttps%253a%252f%252fclick.tanx.com%'
                  or resp_landing_desc like
                     '%https://render.alipay.com/p/s/ulink?scheme=alipays%3a%2f%2fplatformapi%2fstartapp%3fappId%3d2018090761255717%26page%3dpages%252Fwebview-redirect%252Fwebview-redirect%253Furl%253Dhttps%25253a%25252f%25252fclick.tanx.com%'
           , 1, 0))                                                            total_alipay,
       sum(if(resp_landing_desc like '%https://h5.ele.me%' or
              resp_landing_desc like '%eleme://web?action=ali.open.nav&bootImage=0&source=alimama&appkey=%', 1,
              0))                                                              eleme,
       sum(if(dp_dplink like '%alipays://platformapi/startapp?appId=2018090761255717&page=pages%' or
              dp_dplink like '%render.alipay.com%', 1, 0))                     alipay_dp,
       sum(if(dp_dplink like '%eleme://web?action=ali.open.nav&bootImage=0&source=alimama&appkey=31067914&appName=%' or
              dp_dplink like '%https://h5.ele.me%', 1, 0))                     eleme_dp,
       count(1)

from dws.s_ad_ftx_join
where thisdate >= '2020-12-05'
  and thisdate = '2020-12-06'
  and win_ftx_order_id = 41779
group by 1, 2



select case
           when ext_parent_order_id in (40281, 40282, 40283, 40284, 41780, 41781, 41782, 41783) then '趣头条'
           when ext_parent_order_id = 40301 then '韩剧' end vendor


select ext_parent_order_id,
       case
           when imp <= 15 then '1~15'
           when imp > 15 and imp <= 30 then '16~30'
           else '30+' end fre,
       sum(uv)            uv,
       sum(uv * imp)      pv
from (
         select ext_parent_order_id, imp, count(distinct ext_user_id) uv
         from (
                  select ext_parent_order_id, ext_user_id, count(distinct ext_request_id) imp
                  from dwd.d_ad_ftx_impression_data
                  where thisdate = '2020-12-09'
                    and ext_parent_order_id in (40281, 40282, 40283, 40284, 41780, 41781, 41782, 41783, 40301)
                  group by 1, 2
              ) a
         group by 1, 2
     ) b
group by 1, 2


select thisdate,
       vendor,
       case
           when imp <= 15 then '1~15'
           when imp > 15 and imp <= 30 then '16~30'
           else '30+' end fre,
       sum(uv)            uv,
       sum(uv * imp)      pv
from (
         select thisdate, vendor, imp, count(distinct ext_user_id) uv
         from (
                  select thisdate
                       , case
                             when ext_parent_order_id in (40281, 40282, 40283, 40284, 41780, 41781, 41782, 41783)
                                 then '趣头条'
                             when ext_parent_order_id = 40301 then '韩剧' end vendor
                       , ext_user_id
                       , count(distinct ext_request_id)                     imp
                  from dwd.d_ad_ftx_impression_data
                  where thisdate >= '2020-12-09'
                    and thisdate <= '2020-12-10'
                    and ext_parent_order_id in (40281, 40282, 40283, 40284, 41780, 41781, 41782, 41783, 40301)
                  group by 1, 2
              ) a
         group by 1, 2
     ) b
group by 1, 2


-- 广告位超频
select ext_ftx_slot_id,
       case
           when imp <= 15 then '1~15'
           when imp > 15 and imp <= 30 then '16~30'
           else '30+' end fre,
       sum(uv)            uv,
       sum(uv * imp)      pv
from (
         select ext_ftx_slot_id, imp, count(distinct ext_user_id) uv
         from (
                  select ext_ftx_slot_id, ext_user_id, count(distinct ext_request_id) imp
                  from dwd.d_ad_ftx_impression_data d
                           join
                       (
                           select o.id, sp.spot, sp.vendor
                           from u6rds.ftx."order" o
                                    join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
                                         on o.parent_id = sp.id
                           where sp.type = 'porder'
                           group by 1, 2, 3
                       ) t on d.ext_order_id = t.id
                  where thisdate = '2020-12-10'
                    and vendor in (
                      '韩剧TV'
--                                    , '趣头条品牌'
                      )
                    and "hour" = '21'
                  group by 1, 2
              ) a
         group by 1, 2
     ) b
group by 1, 2


select ext_parent_order_id, ext_ftx_slot_id, count(distinct ext_request_id)
from dwd.d_ad_ftx_impression_data
where thisdate = '2020-12-09'
  and ext_parent_order_id in (40281, 40282, 40283, 40301)
group by 1, 2



select count(distinct ext_user_id), count(distinct ext_request_id)
from dwd.d_ad_ftx_impression_data
where thisdate = '2020-12-09'
  and ext_parent_order_id in (40281, 40282, 40283, 40284, 41780, 41781, 41782, 41783, 40301)


select substr('2020-12-07 08:30:03', 12, 2)
           presto --execute "
select ext_user_id, ext_order_id, max(pv)
from (
         select ext_user_id,
                ext_order_id,
                count(ext_request_id) over (partition by ext_user_id) pv
         from dwd.d_ad_ftx_impression_data
         where ext_order_id in
               (40294, 40295, 40303, 40304, 40305, 40306, 40307, 40308, 40309, 40310, 41711, 41712, 41713, 41714, 41722,
                41723, 42081, 42082)
           and thisdate = '2020-12-10'
     ) a
group by 1, 2
    " --output-format TSV > /tmp/hanju;"


select if(ftx_order_id in (41703, 41705, 41707, 41709), '1661_android', '1662_ios'),
       count(distinct ext_user_id),
       count(distinct ext_request_id)
from dwd.d_ad_ftx_impression_data a
where thisdate = '2020-12-11'
  and ftx_order_id in (41703, 41705, 41707, 41709, 41704, 41706, 41708, 41710)
group by 1



select if(diff <= 5, diff, 6) "点击到唤起之间时间差（秒）", count(1)
from (
         select ext_request_id,
                date_diff('second', cast(clk_time as timestamp), cast(ali_test_time as timestamp)) diff
         from (
                  select ext_request_id, substr("timestamp", 1, length("timestamp") - 2) clk_time
                  from dwd.d_ad_ftx_click_data
                  where thisdate = '2020-12-14'
                    and ext_ad_id = 455878
              ) a
                  join
              (
                  select url_extract_parameter(replace(url_decode(raw_url), 'action=', 'http://abc?'),
                                               'reqid') as req_id,
                         "timestamp"                       ali_test_time
                  from dwd.d_ad_action
                  where thisdate = '2020-12-14'
                    and "action" = 'ali_test'
                    and ad_id = '455878'
              ) b on a.ext_request_id = b.req_id
     ) c
group by 1
order by 1



select action, if(diff <= 5, diff, 6) "点击到唤起之间时间差（秒）", count (1)
from (
    select if(c.req_id is null, 'no_ali_test', 'ali_test') action,
    date_diff('second', cast (clk_time as timestamp), cast (dp_time as timestamp)) diff
    from (
    select ext_request_id, substr("timestamp", 1, length ("timestamp") - 2) clk_time
    from dwd.d_ad_ftx_click_data
    where thisdate = '2020-12-11'
    and ext_ad_id = 455581
    ) a
    join
    (
    select ext_request_id, "timestamp" dp_time
    from dwd.d_ad_ftx_dp_track_log
    where thisdate = '2020-12-11'
    and ext_ad_id = 455581
    ) b on a.ext_request_id = b.ext_request_id
    left join
    (
    select url_extract_parameter(replace(url_decode(raw_url), 'action=', 'http://abc?'),
    'reqid') as req_id
    -- "timestamp"                       ali_test_time
    from dwd.d_ad_action
    where thisdate = '2020-12-11'
    and "action" = 'ali_test'
    and ad_id = '455581'
    ) c on a.ext_request_id = c.req_id
    ) d
group by 1, 2



select count(distinct ext_request_id), count(1)
from d_ad_ftx_dp_track_log
where thisdate = '2020-12-11'
  and ext_ad_id = 455581



select thisdate,
       if(ext_mobile_idfa is not null and ext_mobile_idfa <> '', 'ios', 'android') os,
       count(distinct ext_request_id),
       count(1)
from dwd.d_ad_ftx_impression_data
where thisdate >= '2020-12-05'
  and thisdate <= '2020-12-06'
  and ext_parent_order_id = 41778
group by 1, 2
order by 1, 2


select *
--        thisdate,
--        if(ext_mobile_idfa is not null and ext_mobile_idfa <> '', 'ios', 'android') os,
--        count(ext_request_id)
from dwd.d_ad_ftx_click_data
where thisdate >= '2020-12-05'
  and thisdate <= '2020-12-06'
  and ext_parent_order_id = 41778
-- group by 1, 2
-- order by 1, 2


select *
from dwd.d_ad_ftx_response
where thisdate = '2020-12-05'
  and thisdate <= '2020-12-06'
  and custom_parent_order_id = 41778 limit 100;


select *
from dws.s_ad_ftx_join
where thisdate = '2020-12-05'
  and thisdate <= '2020-12-06'
  and clk_ext_parent_order_id = 41778 limit 100



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 频次
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
                         count(distinct ext_user_id) uv

                  from (
                           select b.spot_id,
                                  a.ext_user_id,
                                  count(distinct ext_request_id) as pv
                           from dwd.d_ad_impression a
                                    join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34623)

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
                           where a.thisdate = '2021-01-20'
                             and ext_adgroup_id in (select id from u6rds.ad_fancy.ad_group where spot_id in (34623))
                             -- and spot_id =34623

                           group by 1, 2
                       ) t
                  group by 1, 2
              ) c
         group by 1
     ) d
order by 1

-- 频次
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
                           from dwd.d_ad_ftx_click_data a

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
                           where a.thisdate = '2021-01-20'
                                 -- and spot_id =34623

                           group by 1, 2
                       ) t
                  group by 1, 2
              ) c
         group by 1
     ) d
order by 1


-- 间隔
select id,
       s30,
       1.0000 * s30 / t,
       s60 - s30,
       1.0000 * (s60 - s30) / t,
       s61,
       1.0000 * s61 / t,
       t
from (
         select spot_id             id,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
--                         else 0 end) s5,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
--                         else 0 end) s10,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) > 60 then 1
                        else 0 end) s61,
                sum(imp)            t
         from (
                  select spot_id, time
                          , lag(time, 1, cast ('1970-01-01 00:00:00' as timestamp )) over(partition by spot_id, ext_user_id order by time) as p_time
                          , lead(time, 1, cast ('2099-12-31 23:59:59' as timestamp )) over(partition by spot_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select b.spot_id, ext_user_id
                      -- timestamp imp, time click
                          , cast (replace(timestamp, '_', ' ') as timestamp) as time
                      -- from dwd.d_ad_clicklog_day a
                      from dwd.d_ad_impression a
                      join u6rds.ad_fancy.ad_group b on b.id=a.ext_adgroup_id and b.spot_id in (34623)
                      where thisdate='2021-01-20'
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



select id,
       s5,
       1.000 * s5 / t,
       s10,
       1.000 * s10 / t,
       s30,
       1.000 * s30 / t,
       s60,
       1.000 * s60 / t,
       s61,
       1.000 * s61 / t,
       t
from (
         select amo_order_id        id,
                sum(case
                        when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
                        else 0 end) s5,
                sum(case
                        when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
                        else 0 end) s10,
                sum(case
                        when date_diff('second', time, a_time) <= 30 or date_diff('second', p_time, time) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when date_diff('second', time, a_time) <= 60 or date_diff('second', p_time, time) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when date_diff('second', time, a_time) > 60 or date_diff('second', p_time, time) > 60 then 1
                        else 0 end) s61,
                sum(imp)            t
         from (
                  select amo_order_id, time
                          , lag(time, 1) over(partition by amo_order_id, ext_user_id order by time) as p_time
                          , lead(time, 1) over(partition by amo_order_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select amo_order_id, ext_user_id
                          , cast (timestamp as timestamp) as time
                      --from dwd.d_ad_ftx_impression_data a
                       from dwd.d_ad_ftx_click_data a
                      join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
                      from u6rds.ftx."order" o
                      join u6rds.ftx.order_detail_amo_order b on o.id=b.order_id
                      where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
                      group by 1, 2) b on a.ext_order_id=b.id
                      where thisdate='2021-01-23'
                      -- imp
                      -- and hour = '19'
                      -- click
                      -- and timestamp >= '2021-01-20 19:00:00'
                      -- and timestamp < '2021-01-20 20:00:00'
                      ) a
              ) b
         group by 1
         order by 1
     )
order by 1


-- refer
select b.amo_order_id, count(referer) "总量", sum(if(referer is null or referer = '', 0, 1)) "异常"
from dwd.d_ad_ftx_impression_data a
         join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
               from u6rds.ftx."order" o
                        join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
               where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
               group by 1, 2) b on a.ext_order_id = b.id
where thisdate = '2021-01-20'
group by 1
order by 1


select b.spot_id, count(referer) "总量", sum(if(referer is null or referer = '', 0, 1)) "异常"
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624, 34623)
where thisdate = '2021-01-20'
group by 1

-- ua
select b.amo_order_id, count(anonymous_ua) "总量", sum(if(anonymous_ua = 0, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data a
         join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
               from u6rds.ftx."order" o
                        join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
               where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
               group by 1, 2) b on a.ext_order_id = b.id
where thisdate = '2021-01-20'
group by 1
order by 1

select b.spot_id, count(anonymous_ua) "总量", sum(if(anonymous_ua = 0, 1, 0)) "异常"
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624, 34623)
where thisdate = '2021-01-20'
group by 1
order by 1

-- 安卓10
select b.amo_order_id, count(user_agent) "总量", sum(if(ext_mobile_oaid is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data a
         join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
               from u6rds.ftx."order" o
                        join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
               where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
               group by 1, 2) b on a.ext_order_id = b.id
where thisdate = '2021-01-20'
  and user_agent like '%Android 1%'
group by 1
order by 1

select b.spot_id, count(user_agent) "总量", sum(if(ext_mobile_oaid is null, 1, 0)) "异常"
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34623)
where thisdate = '2021-01-20'
  and user_agent like '%Android 1%'
group by 1
order by 1

-- Imei_md5 && oaid  && idfa为空
select b.amo_order_id,
       count(*)                                                                                           "总量",
       sum(if(ext_mobile_imei_md5 is null and ext_mobile_oaid is null and ext_mobile_idfa is null, 1, 0)) "异常"
from dwd.d_ad_ftx_impression_data a
         join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
               from u6rds.ftx."order" o
                        join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
               where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
               group by 1, 2) b on a.ext_order_id = b.id
where thisdate = '2021-01-20'
group by 1
order by 1


select b.spot_id,
       count(*)                                                                                           "总量",
       sum(if(ext_mobile_imei_md5 is null and ext_mobile_oaid is null and ext_mobile_idfa is null, 1, 0)) "异常"
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624, 34623)
where thisdate = '2021-01-20'
group by 1
order by 1


-- zong
select count(distinct uid)
from (
         select ext_user_id uid
         from dwd.d_ad_ftx_impression_data a
                  join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
                        from u6rds.ftx."order" o
                                 join u6rds.ftx.order_detail_amo_order b on o.id = b.order_id
                        where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
                        group by 1, 2) b on a.ext_order_id = b.id
         where thisdate = '2021-01-20'
         union all
         select ext_user_id uid
         from dwd.d_ad_impression a
                  join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624, 34623)
         where thisdate = '2021-01-20'
     )


select ext_ip, sum(t)
from (
         select id,
                ext_user_id,
                ext_ip,
                case
                    when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
                    else 0 end as t
         from (
                  select time, id, ext_user_id, ext_ip
                          , lag(time, 1) over(partition by amo_order_id, ext_user_id order by time) as p_time
                          , lead(time, 1) over(partition by amo_order_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select amo_order_id, b.id, ext_user_id, ext_ip
                          , cast (timestamp as timestamp) as time
                      from dwd.d_ad_ftx_impression_data a
                      join (select o.id, b.amo_order_id-- , sp.spot , sp.vendor
                      from u6rds.ftx."order" o
                      join u6rds.ftx.order_detail_amo_order b on o.id=b.order_id
                      where b.amo_order_id = 3016
                      group by 1, 2) b on a.ext_order_id=b.id
                      where thisdate='2021-01-20'
                      -- imp
                      and hour = '20'
                      ) a
              ) b
     ) t1
group by 1
order by 2 desc



select b.spot_id,
       a.ext_user_id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624, 34623)

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
where a.thisdate = '2021-01-21'
  and ext_adgroup_id in (select id from u6rds.ad_fancy.ad_group where spot_id in (34624))
  -- and spot_id =34623

group by 1, 2
having count(distinct ext_request_id) > 500



select id,
       s30,
       1.0000 * s30 / t,
       s60 - s30,
       1.0000 * (s60 - s30) / t,
       s120 - s60,
       1.0000 * (s120 - s60) / t,
       s121,
       1.0000 * s121 / t,
       t
from (
         select spot_id             id,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
--                         else 0 end) s5,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
--                         else 0 end) s10,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 120 then 1
                        else 0 end) s120,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) > 120 then 1
                        else 0 end) s121,
                sum(imp)            t
         from (
                  select spot_id, time
                          , lag(time, 1, cast ('1970-01-01 00:00:00' as timestamp )) over(partition by spot_id, ext_user_id order by time) as p_time
                          , lead(time, 1, cast ('2099-12-31 23:59:59' as timestamp )) over(partition by spot_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select b.spot_id, ext_user_id
                      -- timestamp imp, time click
                          , cast (replace(timestamp, '_', ' ') as timestamp) as time
                      -- from dwd.d_ad_clicklog_day a
                      from dwd.d_ad_impression a
                      join u6rds.ad_fancy.ad_group b on b.id=a.ext_adgroup_id and b.spot_id = 34623 -- a.ext_slot_id in ('36282056', '36282251')-- 36282056, 36282251,36282610', '36282620
                      where thisdate='2021-01-20'
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


-- 唤起
select count(a.ext_request_id)                              "总点击",
       sum(if(a.ignore_rule = 0, 1, 0))                     "有效点击",
       count(b.ext_request_id)                              "唤起点击",
       count(if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from dwd.d_ad_clicklog_day a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         join u6rds.ad_fancy.ad_group c on c.id = a.ext_adgroup_id and c.spot_id = 34623
where a.thisdate = '2021-01-20'


select case
           when contains(d.bid_req_adx_dmp_rules, '301948') then '有淘'
           when d.bid_req_adx_dmp_rules is null then '无法关联'
           else '无淘' end                                    "标签",
       count(a.ext_request_id)                              "总点击",
       sum(if(a.ignore_rule = 0, 1, 0))                     "有效点击",
       count(b.ext_request_id)                              "唤起点击",
       count(if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_order_id
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id
    from dspv2_bidding_log
    where thisdate = '2021-01-20'
    group by 2, 1
) d
                   on a.ext_user_id = d.bid_req_user_id
         join (
    select o.id, b.amo_order_id-- , sp.spot , sp.vendor
    from u6rds.ftx."order" o
             join u6rds.ftx.order_detail_amo_order b
                  on o.id = b.order_id
    where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
    group by 1, 2
) c
              on a.ext_order_id = c.id
group by 1


select case
           when contains(d.bid_req_adx_dmp_rules, '301948') then '有淘'
           when d.bid_req_adx_dmp_rules is null then '无法关联'
           else '无淘' end                                             "标签",
       count(distinct a.ext_request_id)                              "总点击",
       count(if(a.ignore_rule = 0, a.ext_request_id, null))          "有效点击",
       count(distinct b.ext_request_id)                              "唤起点击",
       count(distinct if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_order_id, ext_adgroup_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id, bid_req_id
    from dspv2_bidding_log
    where thisdate = '2021-01-20'
) d
                   on a.ext_request_id = d.bid_req_id
         join u6rds.ad_fancy.ad_group c
              on c.id = a.ext_adgroup_id and c.spot_id = 34623
group by 1


select case
           when t.ext_user_id is not null then '重合'
           else 'ICON' end,
       count(a.ext_request_id)                              "总点击",
       sum(if(a.ignore_rule = 0, 1, 0))                     "有效点击",
       count(b.ext_request_id)                              "唤起点击",
       count(if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_adgroup_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         join u6rds.ad_fancy.ad_group c
              on c.id = a.ext_adgroup_id and c.spot_id = 34624

         left join (
    select distinct a.ext_user_id
    from (
             select ext_user_id, ext_adgroup_id
             from dwd.d_ad_clicklog_day
             where thisdate = '2021-01-20'
         ) a
             join u6rds.ad_fancy.ad_group c
                  on c.id = a.ext_adgroup_id and c.spot_id = 34623
) t
                   on a.ext_user_id = t.ext_user_id
group by 1



select a.ext_user_id, a.ext_request_id, d.bid_req_user_id, d.bid_req_id
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_order_id, ext_adgroup_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id, bid_req_id
    from dspv2_bidding_log
    where thisdate = '2021-01-20'
) d
                   on a.ext_request_id = d.bid_req_id
         join u6rds.ad_fancy.ad_group c
              on c.id = a.ext_adgroup_id and c.spot_id = 34623 limit 50



select flag, count(distinct id), sum(req)
from (
         select id, sum(distinct flag) flag, sum(req) req
         from (
                  select id, flag, count(bid_req_id) req
                  from (
                           select bid_req_user_id                                     id,
                                  bid_req_id,
                                  if(contains(bid_req_adx_dmp_rules, '301948'), 1, 2) flag
                           from dspv2_bidding_log
                           where thisdate = '2021-01-20'
                             and bid_req_adx_slot_id in ('36282610', '36282620')
                       ) a
                  group by 1, 2
              ) t
         group by 1
     ) t1
group by 1



select case
           when contains(d.bid_req_adx_dmp_rules, '301948') then '有淘'
           when d.bid_req_adx_dmp_rules is null then '无法关联'
           else '无淘' end                                             "标签",
       count(distinct a.ext_request_id)                              "总点击",
       count(if(a.ignore_rule = 0, a.ext_request_id, null))          "有效点击",
       count(distinct b.ext_request_id)                              "唤起点击",
       count(distinct if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_order_id
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id, bid_req_id
    from dspv2_bidding_log
    where thisdate = '2021-01-20'
) d
                   on a.ext_request_id = d.bid_req_id
         join (
    select o.id, b.amo_order_id-- , sp.spot , sp.vendor
    from u6rds.ftx."order" o
             join u6rds.ftx.order_detail_amo_order b
                  on o.id = b.order_id
    where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
    group by 1, 2
) c
              on a.ext_order_id = c.id
group by 1


-- 下拉二楼/ICON
select case
           when contains(d.bid_req_adx_dmp_rules, '301948') then '有淘'
           when d.bid_req_adx_dmp_rules is null then '无法关联'
           else '无淘' end                                             "标签",
       count(distinct a.ext_request_id)                              "总点击",
       count(if(a.ignore_rule = 0, a.ext_request_id, null))          "有效点击",
       count(distinct b.ext_request_id)                              "唤起点击",
       count(distinct if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_order_id, ext_adgroup_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id, bid_req_id
    from dspv2_bidding_log
    where thisdate = '2021-01-20'
) d
                   on a.ext_request_id = d.bid_req_id
         join u6rds.ad_fancy.ad_group c
              on c.id = a.ext_adgroup_id and c.spot_id = 34624
group by 1



select case
           when t.ext_user_id is not null then '重合'
           else '2l' end,
       count(a.ext_request_id)                              "总点击",
       sum(if(a.ignore_rule = 0, 1, 0))                     "有效点击",
       count(b.ext_request_id)                              "唤起点击",
       count(if(a.ignore_rule = 0, b.ext_request_id, null)) "唤起有效点击"
from (
         select ext_user_id, ext_request_id, ignore_rule, ext_adgroup_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-01-20'
     ) a
         left join dwd.d_ad_ftx_dp_track_log b
                   on a.ext_request_id = b.ext_request_id
         join u6rds.ad_fancy.ad_group c
              on c.id = a.ext_adgroup_id and c.spot_id = 34623

         left join (
    select distinct ext_user_id
    from (select ext_user_id, ext_request_id, ignore_rule, ext_order_id
          from dwd.d_ad_ftx_click_data
          where thisdate = '2021-01-20'
         ) a
             join (
        select o.id, b.amo_order_id-- , sp.spot , sp.vendor
        from u6rds.ftx."order" o
                 join u6rds.ftx.order_detail_amo_order b
                      on o.id = b.order_id
        where b.amo_order_id in (3003, 3015, 3016, 3014, 3046, 3025)
        group by 1, 2
    ) c
                  on a.ext_order_id = c.id
) t
                   on a.ext_user_id = t.ext_user_id
group by 1