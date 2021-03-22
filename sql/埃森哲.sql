-- OTT
select case
           when ad_group_name like '%风行%' then '风行'
           when ad_group_name like '%优酷%' then '优酷'
           when ad_group_name like '%腾讯%' then '腾讯'
           when ad_group_name like '%芒果%' then '芒果'
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           end vendor,
       dat,
       sum(cnt_imp)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_name like '%OTT%'
  and dat >= '2021-01-18'
  and dat <= '2021-01-24'
group by 2, 1


-- client otv
select case
           when ad_group_name like '%风行%' then '风行'
           when ad_group_name like '%优酷%' then '优酷'
           when ad_group_name like '%腾讯%' then '腾讯'
           when ad_group_name like '%芒果%' then '芒果'
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(t_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in
      (245138,
       245140,
       245141,
       245142,
       245143,
       245144)
  and dat >= '2021-01-11'
  and dat <= '2021-01-17'
group by 2, 1

-- talent otv 真实数据
select case
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           when ad_group_name like '%腾讯%' then '腾讯'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(v_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in (245180,
                      245182,
                      245187)
  and dat >= '2021-01-11'
  and dat <= '2021-01-17'
group by 2, 1


-- security otv
select case
           when ad_group_name like '%腾讯%' then '腾讯'
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(t_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in (245408,
                      245409,
                      245411)
  and dat >= '2021-01-11'
  and dat <= '2021-01-17'
group by 2, 1


-- sustainable cloud otv 真实数据
select ad_group_name,
       dat,
       cnt_imp,
       v_click
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in (245180,
                      245182,
                      245187)
  and dat >= '2021-01-11'
  and dat <= '2021-01-18'
limit 30



-- 2020
--  talentotv 真实数据
select case
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           when ad_group_name like '%腾讯%' then '腾讯'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(t_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in (242024,
                      242025,
                      242027)
  and dat >= '2020-12-28'
  and dat <= '2020-12-31'
group by 2, 1


-- sustainable cloud otv 真实数据
select case
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           when ad_group_name like '%腾讯%' then '腾讯'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(t_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in (240436,
                      240437,
                      240439)
  and dat >= '2020-12-28'
  and dat <= '2020-12-31'
group by 2, 1


-- client otv
select case
           when ad_group_name like '%风行%' then '风行'
           when ad_group_name like '%优酷%' then '优酷'
           when ad_group_name like '%腾讯%' then '腾讯'
           when ad_group_name like '%芒果%' then '芒果'
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           else '其他'
           end vendor,
       dat,
       sum(cnt_imp),
       sum(t_click)
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in
      (240380,
       240381,
       240382,
       240383,
       240386,
       240387,
       240390,
       240391,
       240396,
       240397,
       240398,
       240399,
       240402,
       240403)
  and dat >= '2020-12-28'
  and dat <= '2020-12-31'
group by 2, 1


-- client otv

select case
           when ad_group_name like '%爱奇艺%' then '爱奇艺'
           when ad_group_name like '%今日头条%' then '今日头条'
           when ad_group_name like '%凤凰新闻%' then '凤凰新闻'
           when ad_group_name like '%豆瓣%' then '豆瓣'
           when ad_group_name like '%芒果%' then '芒果'
           when ad_group_name like '%蜻蜓%' then '蜻蜓'
           when ad_group_name like '%腾讯视频%' then '腾讯视频'
           when ad_group_name like '%新浪新闻%' then '新浪新闻'
           when ad_group_name like '%优酷%' then '优酷'
           when ad_group_name like '%知乎%' then '知乎'
           when ad_group_name like '%哔哩哔哩%' then '哔哩哔哩'
           when ad_group_name like '%b站%' then '哔哩哔哩'
           when ad_group_name like '%腾讯新闻%' then '腾讯新闻'
           when ad_group_name like '%网易新闻%' then '网易新闻'
           when ad_group_name like '%搜狐新闻%' then '搜狐新闻'
           when ad_group_name like '%喜马拉雅%' then '喜马拉雅'
           when ad_group_name like '%风行视频%' then '风行视频'
           when ad_group_name like '%红板报%' then '红板报'
           else ad_group_name
           end      vendor,
       dat,
       sum(cnt_imp) imp,
       sum(t_click) click
from rpt_fancy.rpt_advertiser
where advertiser_id = 2003397
  and ad_group_id in
      (248279,
       248280,
       248281,
       248282,
       248283,
       248284,
       248285,
       248286,
       248289,
       248290,
       248293,
       248294,
       248313,
       248314,
       248344,
       248345)
  and dat >= '2021-01-18'
  and dat <= '2021-01-24'
group by 2, 1;


