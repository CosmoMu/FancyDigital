-- MaxCompute(ODPS) SQL
--**************************************************************************
-- ** 所属主题: 每日测验
-- ** 功能描述: 答吴老师问题
-- ** 创建者 : Cosmo Mu
-- ** 创建日期: 20201230
-- ** 修改日志: 第一次测验
-- ** 修改日期: 20201230
-- yyyymmdd name comment
-- 20201230 Cosmo 回答12月30日问题
--**************************************************************************

-- part 1
select Student.Sid
     , Sname
from Student
   , SC
   , Course
where Student.Sid = SC.Sid
  and SC.Cid = Course.Cid
  and Course.Cname = '计算机原理'

-- part 2
select Course.Cid
     , Cname
from Course
   , Student
   , SC
where Student.Sname = '周星驰'
  and SC.Cid = Course.Cid
  and Student.Sid = SC.Sid


-- part 3
select Student.Sid
     , Student.Sname
from SC
   , Student
where SC.Sid = Student.Sid
group by 1
having count(SC.Cid) = 5

-- part 4
select a.Sid
from (
         select Sid
              , score
         from SC
         where Cid = '001'
     ) a
         join
     (
         select Sid
              , score
         from SC
         where Cid = '002'
     ) b
     on a.Sid = b.Sid
where a.score > b.score

-- part 5
select SC.Sid
     , Sname
     , case
           when score >= 80 then '优秀'
           when score < 60 then '不及格'
           else '及格' end '成绩情况'
from SC
         join Student
              on SC.Sid = Student.Sid
where Cid = '003'
group by 1, 2

-- part 6
select SC.Sid, Sname, avg(score) '平均成绩'
from SC
         join Student
              on SC.Sid = Student.Sid
group by 1, 2
having avg(score) > 60

-- part 7
select Student.Sid
     , Sname
     , count(SC.Cid) '选课数'
     , sum(SC.Score) '总成绩'
from SC
         join Student
              on SC.Sid = Student.Sid
group by 1, 2

-- part 8
select count(distinct Tid) '人数'
from Teacher
where Tname like "杨%"

-- part 9
select Sid, Sname
from Student
where Sid not in
      (
          select SC.sid
          from SC
                   join Course
                        on SC.Cid = Course.Cid
                   join Teacher
                        on Course.Tid = Teacher.Tid
          where Tname = '张三'
      )
group by 1, 2

-- part 10
select Student.Sid
     , Sname
from Student
         join SC
              on SC.Sid = Student.Sid
group by 1, 2
having sum(
               case
                   when Cid = 1 then 1
                   else 0 end)
           *
       sum(
               case
                   when Cid = 2 then 1
                   else 0 end) <> 0


-- part 11
select Student.Sid
     , Sname
from Student
         join SC
              on Student.Sid = SC.Sid
where Cid in (
    select Cid
    from Course
             join Teacher
                  on Course.Tid = Teacher.Tid
    where Tname = '鬼谷子'
)
group by 1, 2
having count(distinct SC.Cid) = (
    select count(distinct Cid)
    from Course
             join Teacher
                  on Course.Tid = Teacher.Tid
    where Tname = '鬼谷子')

-- part 12
select Student.Sid
     , Sname
from Student
         left join
     (
         select Sid
         from SC
         where score >= 60) a
     on Student.Sid = a.Sid
where a.Sid is null
group by 1, 2

-- part 13
select Student.Sid
     , Sname
from Student
         join SC
              on Student.Sid = SC.Sid
group by 1, 2
having count(distinct SC.Cid) = (select count(distinct Cid) from Course)

-- part 14
select Student.Sid
     , Sname
from Student
         left join SC
                   on Student.Sid = SC.Sid
group by 1, 2
having count(distinct SC.Cid) < (select count(distinct Cid) from Course)

-- part 15
select Student.Sid
     , Sname
from Student
         join SC
              on Student.Sid = SC.Sid
where Student.Sid <> 1
  and Cid in (select Cid from SC where Sid = 1)
group by 1, 2

-- part 16
select Student.Sid
     , Sname
from SC
         join Student
              on Student.Sid = SC.Sid
         join (select distinct Cid from SC where Sid = 1) a
              on a.Cid = SC.Cid
where Student.Sid != '001'
group by 1, 2
having count(distinct SC.Cid) = 1

-- part 17
select Student.Sid
     , Sname
from SC
         join Student
              on Student.Sid = SC.Sid
where Student.Sid in
      (select Sid
       from SC
       where Cid in
             (select Cid
              from SC
              where Sid = '002')
         and Sid <> '002'
       group by 1
       having count(Cid) = (select count(Cid) from SC where Sid = '002'))
group by 1, 2
having count(Cid) = (select count(Cid) from SC where Sid = '002')

-- part 18
select a.*
     , if(Chinese is null, 0, 1) + if(Math is null, 0, 1) + if(English is null, 0, 1)   "有效课程"
     , (if(Chinese is null, 0, Chinese) + if(Math is null, 0, Math) + if(English is null, 0, English)) /
       (if(Chinese is null, 0, 1) + if(Math is null, 0, 1) + if(English is null, 0, 1)) "有效平均分"
from (
         select Student.Sid
              , max(case when Cname = '计算机原理' then score end) as Chinese
              , max(case when Cname = '非攻' then score end)    as Math
              , max(case when Cname = '机关术' then score end)   as English
         from SC
                  join Course
                       on SC.Cid = Course.Cid
                  join Student
                       on Student.Sid = SC.Sid
         group by 1
     ) a
group by 1
order by 6

-- part 19
select Student.Sid
     , Sname
from Student
         join SC
              on Student.Sid = SC.Sid
group by 1, 2
having count(distinct Cid) = 5

-- part 20
select a.*, rank() over(order by a.av)
from (
    select Student.Sid
         , Sname
         , avg(score) av
    from Student
    left join SC
    on Student.Sid = SC.Sid
    group by 1, 2) a

-- part 21
select Course.Cid
     , max(score)
     , min(score)
from Course
left join SC
on Course.Cid = SC.Cid
group by 1

-- part 22
select b.Cid
     , round(b.avgs,2) avgs
     , concat(round(ifnull(a.num / b.num,0)*100,2),'%') passrate
from (
    select Cid
         , count(distinct Sid) num
    from SC
    where score >= 60
    group by 1
    ) a
right join (
    select Cid
         , count(distinct Sid) num
         , avg(score) avgs
    from SC
    group by 1
    ) b
on a.Cid = b.Cid
group by 1
order by 2, 3 desc

-- part 23
select b.Cid
     , Cname
     , round(b.avgs, 2) avgs
     , concat(round(ifnull(a.num / b.num, 0) * 100, 2), '%') passrate
from (
    select Cid
         , count(distinct Sid) num
    from SC
    where score >= 60
      and Cid in ('002', '003', '004')
    group by 1
    ) a
right join (
    select Cid
         , count(distinct Sid) num
         , avg(score)          avgs
    from SC
    where Cid in ('002', '003', '004')
    group by 1
) b
on a.Cid = b.Cid
join Course
on Course.Cid = b.Cid
group by 1, 2

-- part 24
select a.Cid
     , Cname
     , Teacher.Tid
     , Tname
     , avgs
from (
    select Cid
         , ifnull(avg(score), 0) avgs
    from SC
    group by 1
    ) a
join Course
on Course.Cid = a.Cid
join Teacher
on Teacher.Tid = Course.Tid
group by 1, 2, 3, 4, 5
order by 5 desc

-- part 25
select Course.Cid
     , Cname
     , sum(if(score >= 85, 1, 0))                '[100-85]'
     , sum(if(score >= 70 and score < 85, 1, 0)) '[84-70]'
     , sum(if(score >= 60 and score < 70, 1, 0)) '[69-60]'
     , sum(if(score < 60, 1, 0))                 '[<60]'
from SC
join Course
on SC.Cid = Course.Cid
group by 1, 2

-- part 26
select Course.Cid
     , Cname
     , count(distinct Sid) '人数'
from SC
join Course
on SC.Cid = Course.Cid
group by 1, 2

-- part 27
select Student.Sid
     , Sname
from Student
left join (
    select Sid, count(Sid) c
    from SC
    group by 1
    ) a
on a.Sid = Student.Sid
where a.c = 1
group by 1, 2

-- part 28
select count(distinct Sid) '人数'
from Student
where Ssex='男'

-- part 29
select *
from Student
where Sname like '李%'

-- part 30
select Sname
     , count(distinct Sid) '人数'
from Student
group by 1
having count(distinct Sid) > 1

-- part 31
select *
from Student
where year(Sage) = 1988

-- part 32
select Course.Cid
     , avg(score) avgs
from Course
left join SC
on Course.Cid = SC.Cid
group by 1
order by avgs asc, Cid desc

-- part 33
select Student.Sid
     , Sname
     , score
from SC
join Student
on SC.Sid = Student.Sid
join Course
on SC.Cid = Course.Cid
where Cname = '数学'
  and score < 60

-- part 34
select SC.Sid
     , Sname
     , Cname
     , score
from SC
join Student
on SC.Sid = Student.Sid
join Course
on SC.Cid = Course.Cid
where score > 70
group by 1, 2, 3, 4

-- part 35
select SC.Cid
     , Cname
from SC
join Course
on SC.Cid = Course.Cid
where score < 60
group by 1, 2

-- part 36
select SC.Sid
     , Sname
from SC
join Student
on SC.Sid = Student.Sid
where score > 80
  and Cid = '003'
group by 1, 2

-- part 37
select count(distinct Sid)
from SC

-- part 38
select SC.Sid
     , Sname
     , score
from Student
join SC
on Student.Sid = SC.Sid
where Cid in (
    select Cid
    from Course
    join Teacher
    on Course.Tid = Teacher.Tid
      and Teacher.Tname = '王五')
group by 1, 2, 3
order by score desc
limit 1

-- part 39
select Course.Cid
     , Cname
     , count(distinct Sid)
from Course
left join SC
on Course.Cid = SC.Cid
group by 1, 2

-- part 40
select distinct a.Sid
              , a.Cid
              , a.score
from SC a
join SC b
on a.score = b.score
  and a.Sid <> b.Sid

-- part 41
select Cid
     , count(distinct Sid)
from SC
group by 1
having count(distinct Sid) > 10
order by 2 desc

-- part 42
select SC.Cid
     , Cname
from SC
join Course
on SC.Cid = Course.Cid
group by 1, 2
having count(distinct Sid) = (select count(distinct Sid) from Student)

-- part 43
select Sid
     , avg(score) avgs
from SC
group by 1
having Sid in (
    select Sid
    from SC
    where score < 60
    group by 1
    having count(Cid) > 2
    )

-- part 44
select SC.Sid, Sname
from SC
join Student
on SC.Sid = Student.Sid
where Cid = '004'
  and score < 60
order by score desc

-- part 45
select SC.Sid
     , Sname
from SC
join Student
on SC.Sid = Student.Sid
join Course
on SC.Cid = Course.Cid
where Cname = '化学'
order by score desc
limit 10, 10