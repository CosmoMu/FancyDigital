select a.thisdate,
       --查MOB 要if语句，加group by
       -- if(adg.name like '%信息流%', 'feed', 'banner')                                             as format,
       sum(a.imp)                                                                              as imp,
       sum(a.uv)                                                                               as uv,
       sum(if(b.click is null, 0, b.click))                                                    as click,
       sum(stay_land)                                                                          as stay_land,
       sum(stay_time)                                                                          as stay_time,
       sum(if(land.land is null, 0, land.land))                                                as land,
       sum(if(land.land is null, 0, land.land)) - sum(if(land.ertiao is null, 0, land.ertiao)) as bounce,
       sum(if(land.page_view is null, 0, land.page_view))                                      as page_view
from (
         select thisdate,
                ext_ad_id,
                count(distinct ext_user_id)    as uv,
                count(distinct ext_request_id) as imp
         from dwd.d_ad_impression
         where ext_order_id = 2902
           and thisdate >= '2020-12-28'
           and thisdate <= '2020-12-31'
         group by 1, 2
     ) a
         left join
     (
         select thisdate,
                ext_ad_id,
                count(ext_request_id) as click
         from dwd.d_ad_clicklog_day
         where thisdate >= '2020-12-28'
           and thisdate <= '2020-12-31'
           and ext_order_id = 2902
         group by 1, 2
     ) b on a.ext_ad_id = b.ext_ad_id and a.thisdate = b.thisdate
         left join u6rds.ad_fancy.ad ad on ad.id = a.ext_ad_id
         left join u6rds.ad_fancy.campaign cam on ad.campaign_id = cam.id
         left join u6rds.ad_fancy.ad_group adg on adg.id = ad.ad_group_id
         left join
     (
         select thisdate,
                ad_id,
                sum(case when stay_time > 1800000 then 0 else stay_time end)  as stay_time,
                count(case when stay_time <= 1800000 then pvid else null end) as stay_land
         from (select pvid,
                      ad_id,
                      thisdate,
                      max(cast(json_extract_scalar(extra_data, '$.staytime') as int)) stay_time
               from dwd.d_ad_action
               where thisdate >= '2020-12-28'
                 and thisdate <= '2020-12-31'
                 and action = 'staytime'
                 and ad_id <> '0'
                 and advertiser_id = '2003003'
               group by 1, 2, 3
              ) tmp
         group by 1, 2
     ) stay on stay.thisdate = a.thisdate and cast(a.ext_ad_id as varchar) = stay.ad_id
         left join
     (
         select thisdate,
                ad_id,
                count(pvid)                                      as page_view,
                count(distinct case
                                   when url_extract_parameter(url_decode(extra_data_referer), 'utm_source') is null
                                       then pvid end)            as land,
                count(distinct case
                                   when url_extract_parameter(url_decode(extra_data_referer), 'utm_source') = 'fancy' or
                                        depth > 1 then pvid end) as ertiao
         from dwd.d_ad_action
         where thisdate >= '2020-12-28'
           and thisdate <= '2020-12-31'
           and advertiser_id = '2003003'
           and ad_id <> '0'
           and action = 'land'
         group by 1, 2
     ) land on a.thisdate = land.thisdate and cast(a.ext_ad_id as varchar) = land.ad_id
where 1 = 1
  and ad.campaign_id in (
    -- mob
    --                     46109, 46118
    --  pc
                         46110, 46119
    )
group by 1
order by 1;


-- https://booking.melia.com/booking/services/E_DataSearcher.jsp?callback=json&idLang=cn
-- 查酒店名字网址
-- 酒店信息 订单shit
-- 一周留两三条数据就够了
select thisdate,
       pvid,
       client_ip,
       cast(json_extract_scalar(extra_data, '$.HotelId') as varchar)       hotelId,
       cast(json_extract_scalar(extra_data, '$.TransactionId') as varchar) transactionId,
       cast(json_extract_scalar(extra_data, '$.amount') as varchar)        amount
from dwd.d_ad_action
where advertiser_id = '2003003'
  and thisdate >= '2020-12-28'
  and thisdate <= '2020-12-31'
  and page_type = 'order'
  and action = 'land';

--
select city,
       count(distinct case
                          when url_extract_parameter(url_decode(extra_data_referer), 'utm_source') is null
                              then pvid end) as land
from dwd.d_ad_action a
         left join dim.dim_geo_city_info b on a.geo_id = b.geo_code
where thisdate >= '2020-11-12'
  and thisdate <= '2020-11-30'
  and advertiser_id = '2003003'
  and ad_id <> '0'
  and action = 'land'
group by 1


--

select a.thisdate,
       sum(a.imp)                                                                              as imp,
       sum(a.uv)                                                                               as uv,
       sum(if(b.click is null, 0, b.click))                                                    as click,
       sum(stay_land)                                                                          as stay_land,
       sum(stay_time)                                                                          as stay_time,
       sum(if(land.land is null, 0, land.land))                                                as land,
       sum(if(land.land is null, 0, land.land)) - sum(if(land.ertiao is null, 0, land.ertiao)) as bounce,
       sum(if(land.page_view is null, 0, land.page_view))                                      as page_view
from (
         select thisdate,
                ext_ad_id,
                count(distinct ext_user_id)    as uv,
                count(distinct ext_request_id) as imp
         from dwd.d_ad_impression
         where ext_order_id = 2816
           and thisdate >= '2020-11-19'
           and thisdate <= '2020-11-22'
         group by 1, 2
     ) a
         left join
     (
         select thisdate,
                ext_ad_id,
                count(ext_request_id) as click
         from dwd.d_ad_clicklog_day
         where thisdate >= '2020-11-19'
           and thisdate <= '2020-11-22'
           and ext_order_id = 2816
         group by 1, 2
     ) b on a.ext_ad_id = b.ext_ad_id and a.thisdate = b.thisdate
         left join u6rds.ad_fancy.ad ad on ad.id = a.ext_ad_id
         left join
     (
         select sum(case when stay_time > 1800000 then 0 else stay_time end)  as stay_time,
                count(case when stay_time <= 1800000 then pvid else null end) as stay_land
         from (select pvid,
                      ad_id,
                      thisdate,
                      max(cast(json_extract_scalar(extra_data, '$.staytime') as int)) stay_time
               from dwd.d_ad_action
               where thisdate = '2020-11-24'
                 and action = 'staytime'
                 and ad_id = '453626'
--                  and advertiser_id = '2003003'
               group by 1, 2, 3
              ) tmp
--          group by 1, 2
     ) stay on stay.thisdate = a.thisdate and cast(a.ext_ad_id as varchar) = stay.ad_id
         left join
     (
         select count(distinct case
                                   when url_extract_parameter(url_decode(extra_data_referer), 'utm_source') is null
                                       then pvid end)            as land,
                count(distinct case
                                   when url_extract_parameter(url_decode(extra_data_referer), 'utm_source') = 'fancy' or
                                        depth > 1 then pvid end) as ertiao
         from dwd.d_ad_action
         where thisdate = '2020-11-24'
--            and advertiser_id = '2003003'
           and ad_id = '453626'
           and action = 'land'
--          group by 1, 2
     ) land on a.thisdate = land.thisdate and cast(a.ext_ad_id as varchar) = land.ad_id

group by 1;


select land, ertiao, stay_time / stay_land / 1000, click
from (
         select ad_id,
                count(distinct pvid)                            as land,
                count(distinct case
                                   when
                                       depth > 1 then pvid end) as ertiao
         from dwd.d_ad_action
         where thisdate = '2020-11-24'
--            and advertiser_id = '2003003'
           and ad_id = '453626'
           and action = 'land'
         group by 1
     ) a
         join
     (
         select ad_id,
                sum(case when stay_time > 1800000 then 0 else stay_time end)  as stay_time,
                count(case when stay_time <= 1800000 then pvid else null end) as stay_land
         from (select pvid,
                      ad_id,
                      max(cast(json_extract_scalar(extra_data, '$.staytime') as int)) stay_time
               from dwd.d_ad_action
               where thisdate = '2020-11-24'
                 and action = 'staytime'
                 and ad_id = '453626'
--                  and advertiser_id = '2003003'
               group by 1, 2
              ) b
         group by 1
     ) c
     on a.ad_id = c.ad_id
         join (
    select ext_ad_id, count(distinct ext_request_id) click
    from dwd.d_ad_clicklog_day
    where thisdate = '2020-11-24'
      and ext_ad_id = 453626
    group by 1
) d
              on a.ad_id = cast(d.ext_ad_id as varchar)
    presto --execute "
select distinct fancy_cookie
from dwd.d_ad_action
where thisdate >= '2020-07-08'
  and thisdate <= '2020-12-07'
  and advertiser_id = '2003003'
  and fancy_cookie <> ''
  and fancy_cookie is not null
  and action = 'land'
    " --output-format TSV > meiliya_land_pc;"
    presto --execute "
select distinct pvid
from dwd.d_ad_action
where thisdate >= '2020-07-08'
  and thisdate <= '2020-12-07'
  and advertiser_id = '2003003'
  and pvid <> ''
  and pvid is not null
  and action = 'land'
    " --output-format TSV > meiliya_land_mob;"
    presto --execute "
select distinct fancy_cookie
from dwd.d_ad_impression
where thisdate >= '2020-07-08'
  and thisdate <= '2020-12-07'
  and ext_advertiser_id = 2003003
  and fancy_cookie <> ''
  and fancy_cookie is not null
  and ext_device_type = 3 " --output-format TSV > meiliya_imp_pc;"




presto --execute "
select distinct ext_user_id
from dwd.d_ad_impression
where thisdate >= '2020-07-08'
  and thisdate <= '2020-12-07'
  and ext_advertiser_id = 2003003
  and ext_device_type in (1, 2)
  and ext_user_id <> ''
  and ext_user_id is not null
    " --output-format TSV > meiliya_imp_mob;"