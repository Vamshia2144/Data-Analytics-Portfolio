-- view for batsmens data 
-- drop view Batsmen_data;
CREATE VIEW Batsmen_data as 
with batter_match_stats as(
select batter,match_id,sum(batter_runs) as runs, count(*) as balls,
sum(case when batter_runs=4 then 1 else 0 end) as fours,
sum(case when batter_runs=6 then 1 else 0 end) as sixes,
sum(case when player_out is not null and player_out=batter then 1 else 0 end) as dismissals
from deliveries group by match_id,batter
)
select batter as batsmen,sum(runs) as total_runs,count(distinct match_id) as matches, sum(balls) as balls, max(runs) as high_score,
case when sum(dismissals)>0 then round(sum(runs)*1.0/sum(dismissals),2) else null end as avg,
round(sum(runs)*100/sum(balls),1) as strike_rate,
sum(case when runs>=30 then 1 else 0 end) as 30s, 
sum(case when runs>=50 then 1 else 0 end) as 50s,
sum(case when runs>=100 then 1 else 0 end) as 100s,
sum(fours) as 4s,sum(sixes) as 6s
 from batter_match_stats group by batter order by total_runs Desc;
 
 select * from Batsmen_data;
 
 -- --------------------------------------------------------------------------------------------------
 -- view for batmens last two seasons
create view Batsmen_l2s_data as
with batsmen_2s_match_stats as(
 select batter,match_id,sum(batter_runs) as runs,count(*) as balls,
sum(case when batter_runs=4 then 1 else 0 end) as fours,
sum(case when batter_runs=6 then 1 else 0 end) as sixes,
sum(case when player_out is not null and player_out=batter then 1 else 0 end) as dismissals
from deliveries 
where season_id in (2025) group by match_id,batter
)
select batter as batsmen,sum(runs) as recent_runs,count(distinct match_id) as recent_matches,sum(balls) as balls,
max(runs) as recent_highest_score,
case when sum(dismissals)>0 then round(sum(runs)*1.0/sum(dismissals),2) else null end as recent_avg,
round(sum(runs)*100/sum(balls),1) as recent_strike_rate,
sum(case when runs>=30 then 1 else 0 end) as 30s,
sum(case when runs>=50 then 1 else 0 end) as 50s,
sum(case when runs>=100 then 1 else 0 end) as 100s,
sum(fours) as 4s,sum(sixes) as 6s
from batsmen_2s_match_stats group by batter order by recent_runs desc;

select * from Batsmen_l2s_data;

-- -------------------------------------------------------------------------------
 -- view for Bowlers_data
 create view Bowlers_data as
 with bowler_match_stats as(
 select bowler,match_id,innings,count(*) as balls_bowled,
 sum(total_runs) as runs_conceded,
SUM(CASE WHEN player_out IS NOT NULL 
                    AND wicket_kind != 'run out' or 'retired hurt' or 'retired out' -- Exclude run outs
               THEN 1 ELSE 0 END) AS wickets
from deliveries group by match_id,bowler,innings
 )
select bowler,sum(wickets) as total_wickets,
count(distinct match_id) as matches,
sum(balls_bowled) as total_balls,
sum(runs_conceded) as runs,
round(sum(runs_conceded)*1.0/sum(wickets),2) as b_average,
round(sum(runs_conceded)*6.0/sum(balls_bowled),2) as economy_rate,
round(sum(wickets)*100.0/sum(balls_bowled/6),2) as b_strike_rate,
max(wickets) as highest_wickets,
sum(case when wickets>=4 then 1 else 0 end) as 4Ws,
sum(case when wickets>=5 then 1 else 0 end) as 5Ws
from bowler_match_stats group by bowler order by total_wickets desc;

select * from  Bowlers_data;

-- -----------------------------------------------------------------------------------
-- view for Bowler last 2 seasons
drop view Bowlers_l2s_data;
 create view Bowlers_l2s_data as
 with bowler_2s_match_stats as(
 select bowler,match_id,innings,count(*) as balls_bowled,
 sum(total_runs) as runs_conceded,
SUM(CASE WHEN player_out IS NOT NULL THEN 1 ELSE 0 END) AS wickets
from deliveries where season_id in (2024,2025) group by match_id,bowler,innings
 )
select bowler,sum(wickets) as recent_wickets,
count(distinct match_id) as matches,
sum(balls_bowled) as total_balls,
sum(runs_conceded) as runs,
round(sum(runs_conceded)*1.0/sum(wickets),2) as recent_average,
round(sum(runs_conceded)*6.0/sum(balls_bowled),2) as recent_economy,
round(sum(wickets)*100.0/sum(balls_bowled/6),2) as recent_strike_rate,
max(wickets) as recent_highwickets,
sum(case when wickets>=4 then 1 else 0 end) as 4Ws,
sum(case when wickets>=5 then 1 else 0 end) as 5Ws
from bowler_2s_match_stats group by bowler order by recent_wickets desc;

select * from Bowlers_l2s_data;

-- -------------------------------------------------------------