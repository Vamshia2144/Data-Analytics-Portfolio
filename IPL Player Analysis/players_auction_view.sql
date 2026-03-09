-- view for vw_auction_batsmen
CREATE OR REPLACE VIEW vw_auction_batsmen AS
WITH recent_bat AS (
    SELECT 
        batsmen AS player, 
        recent_runs,
        COALESCE(`100s`, 0) AS recent_100s,
        COALESCE(`6s`, 0) AS recent_6s,     -- ✅ Perfect column names
        recent_strike_rate,
        recent_matches,
        recent_highest_score
    FROM Batsmen_l2s_data
)
SELECT 
    'batsmen' as role,
    b.batsmen AS player,
    b.total_runs AS career_runs,
    b.strike_rate AS career_sr,
    b.`6s` as career_6s,
    COALESCE(rb.recent_runs, 0) AS recent_runs,
    coalesce(rb.recent_highest_score) as recent_highscore,
    COALESCE(rb.recent_100s, 0) AS recent_100s,
    COALESCE(rb.recent_6s, 0) AS recent_sixes,  -- ✅ Fixed column reference
    CASE 
        WHEN rb.recent_matches IS NOT NULL THEN
            LEAST(
                ROUND(
                    (b.total_runs * 0.1 + 
                     rb.recent_runs * 0.55 +      -- 55% recent emphasis ✅
                     b.strike_rate * 0.05 + 
                     rb.recent_100s * 0.1 + 
                     rb.recent_6s * 0.2) * 110000 / 10000000, 1  -- ✅ Perfect
                ), 20
            )
        ELSE
            LEAST(
                ROUND((b.total_runs * 0.08 + b.strike_rate * 0.03) * 100000 / 10000000, 1), 12
            )
    END AS predicted_cr
FROM Batsmen_data b
LEFT JOIN recent_bat rb ON b.batsmen = rb.player
WHERE b.matches >= 10
ORDER BY predicted_cr DESC;

select player from vw_auction_batsmen limit 100;

-- ------------------------------------------------------------
-- view for vw_auction_bowlers
-- drop view vw_auction_bowlers;
CREATE OR REPLACE VIEW vw_auction_bowlers AS
WITH recent_bowl AS (
    SELECT 
        bowler AS player,
        recent_wickets,
        recent_highwickets,
        COALESCE(`4Ws`, 0) AS recent_4w,
        COALESCE(`5Ws`, 0) AS recent_5w,
        recent_economy,
        matches AS recent_matches
    FROM Bowlers_l2s_data
)
SELECT 
    'bowler' as role,
    bo.bowler AS player,
    bo.total_wickets AS career_wickets,
    COALESCE(rb.recent_wickets, 0) AS recent_wickets,
    coalesce(rb.recent_highwickets, 0) as recent_highwickets,
    bo.economy_rate as career_economy,
    coalesce(rb.recent_economy) as recent_economy,
    COALESCE(rb.recent_4w, 0) AS recent_4w,
    COALESCE(rb.recent_5w, 0) AS recent_5w,
    CASE 
        WHEN rb.recent_matches IS NOT NULL THEN
            LEAST(
                ROUND(
                    (bo.total_wickets * 0.1 +      -- Career baseline ALWAYS 10%
                     COALESCE(rb.recent_wickets, 0) * 0.55 + 
                     COALESCE(rb.recent_4w, 0) * 0.1 + 
                     COALESCE(rb.recent_5w, 0) * 0.25) * 3000000 / 10000000, 1
                ), 20
            )
        ELSE
            LEAST(
                ROUND(bo.total_wickets * 0.1 * 3000000 / 10000000, 1), 12
            )
    END AS predicted_cr
FROM Bowlers_data bo
LEFT JOIN recent_bowl rb ON bo.bowler = rb.player
WHERE bo.matches >= 5
ORDER BY predicted_cr DESC;

select * from vw_auction_bowlers;

-- -----------------------------------------------------------------------------------
-- view for vw_auction_allrounders
CREATE OR REPLACE VIEW vw_auction_allrounders AS
WITH all_round_players AS (
    SELECT 
        b.batsmen AS player,
        b.total_runs AS career_bat_runs,
        COALESCE(bo.total_wickets, 0) AS career_bowl_wkts,
        rb.recent_runs,
        COALESCE(rb.`100s`, 0) AS recent_100s,
        COALESCE(rb.`6s`, 0) AS recent_6s,
        rbo.recent_wickets,
        COALESCE(rbo.`4Ws`, 0) AS recent_4w,
        COALESCE(rbo.`5Ws`, 0) AS recent_5w,
        b.strike_rate,
        rb.recent_strike_rate,
        rb.recent_matches
    FROM Batsmen_data b
    INNER JOIN Bowlers_data bo ON b.batsmen = bo.bowler
    LEFT JOIN Batsmen_l2s_data rb ON b.batsmen = rb.batsmen
    LEFT JOIN Bowlers_l2s_data rbo ON bo.bowler = rbo.bowler
    WHERE b.total_runs >= 500 AND bo.total_wickets >= 20
)
SELECT 
    'allrounder' AS role, 
    player,
    career_bat_runs,
    career_bowl_wkts,
    recent_runs,
    recent_wickets,
    strike_rate,
    recent_strike_rate,
    LEAST(
        ROUND(
            -- Batting (50%) - Updated recent runs to 0.6
            (career_bat_runs * 0.2 + COALESCE(recent_runs, 0) * 0.5 + 
             recent_100s * 0.1 + recent_6s * 0.2) * 100000 / 10000000 +
            
            -- Bowling (50%)
            (career_bowl_wkts * 0.2 + COALESCE(recent_wickets, 0) * 0.6 + 
             recent_4w * 0.1 + recent_5w * 0.1) * 1500000 / 10000000, 1
        ),  -- +2Cr all-rounder premium
        20
    ) AS predicted_cr
FROM all_round_players
ORDER BY predicted_cr DESC;
-- drop view vw_auction_allrounders;
select * from vw_auction_allrounders;

-- -----------------------------------------------------------------------------------
-- view for vw_auction_master
CREATE OR REPLACE VIEW vw_auction_master AS
SELECT DISTINCT
    role, player, predicted_cr, career_runs_or_wkts, recent_runs_or_wkts, highest_runs_or_wkts
FROM (
    -- Batsmen: career_runs, recent_runs, highest score + 100s
    SELECT 
        'Batsmen' AS role, 
        player, 
        predicted_cr,
        career_runs AS career_runs_or_wkts,
        recent_runs AS recent_runs_or_wkts,
        COALESCE(recent_highscore, 0) AS highest_runs_or_wkts
    FROM vw_auction_batsmen
    
    UNION ALL
    
    -- Bowlers: career_wickets, recent_wickets, highest wickets haul
    SELECT 
        'Bowlers' AS role, 
        player, 
        predicted_cr,
        career_wickets AS career_runs_or_wkts,
        recent_wickets AS recent_runs_or_wkts,
        COALESCE(recent_highwickets, 0) AS highest_runs_or_wkts  -- Recent highest wickets
    FROM vw_auction_bowlers
    )combined
ORDER BY predicted_cr DESC;

    UNION ALL
    
    -- Allrounders: weighted recent peaks
    SELECT 
        'Allrounders' AS role, 
        player, 
        predicted_cr,
        (career_bat_runs + career_bowl_wkts * 10) AS career_stat,
        (recent_runs + recent_wickets * 20) AS recent_stat,
        GREATEST(
            COALESCE(recent_best_bat_score, 0), 
            COALESCE(recent_best_wickets, 0) * 25
        ) AS peak_recent  -- Best bat score OR wickets equivalent
    FROM vw_auction_allrounders
) combined
ORDER BY predicted_cr DESC;
select *  from vw_auction_master limit 30;

-- ----------------------------------------------------------------------
-- view for vw_batsmen_yearly_stats
CREATE or replace VIEW vw_batsmen_yearly_stats AS
WITH yearly_match_stats AS (
    SELECT 
        m.season_id,
        d.batter,
        SUM(d.batter_runs) as season_runs,
        COUNT(DISTINCT d.match_id) as matches,
        COUNT(*) as balls,
        SUM(CASE WHEN d.batter_runs=4 THEN 1 ELSE 0 END) as fours,
        SUM(CASE WHEN d.batter_runs=6 THEN 1 ELSE 0 END) as sixes,
        SUM(CASE WHEN d.player_out IS NOT NULL AND d.player_out = d.batter 
                 AND d.wicket_kind != 'run out' THEN 1 ELSE 0 END) as dismissals
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    GROUP BY m.season_id, d.batter, m.match_id  -- Per match first
),
season_summary AS (
    SELECT 
        season_id,
        batter,
        SUM(season_runs) as total_runs,
        SUM(matches) as total_matches,
        round(AVG(season_runs*1.0 / NULLIF(matches,0)),1) as season_avg,
        ROUND(SUM(season_runs)*100.0 / SUM(balls), 1) as season_sr,
        sum(fours) as 4s,
        sum(sixes) as 6s,
        sum(case when season_runs>=50 then 1 else 0 end) as 50s,
        sum(case when season_runs>=100 then 1 else 0 end) as 100s
    FROM yearly_match_stats
    GROUP BY season_id, batter
    HAVING total_runs >= 100  -- IPL quality threshold
)
SELECT * FROM season_summary
ORDER BY season_id DESC, total_runs DESC;
select * from vw_batsmen_yearly_stats;

-- -----------------------------------------------------------------
-- view for vw_bowlers_yearly_stats
CREATE OR REPLACE VIEW vw_bowlers_yearly_stats AS
WITH yearly_bowler_match_stats AS (
    SELECT 
        m.season_id,
        d.bowler,
        COUNT(DISTINCT d.match_id) as matches,
        COUNT(*) as balls_bowled,
        SUM(d.total_runs) as runs_conceded,
        SUM(CASE WHEN d.player_out IS NOT NULL 
                 AND d.wicket_kind != 'run out' 
                 THEN 1 ELSE 0 END) as wickets,
        SUM(CASE WHEN d.wicket_kind = 'caught' THEN 1 ELSE 0 END) as catches_taken
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    GROUP BY m.season_id, d.bowler, m.match_id
),
season_summary AS (
    SELECT 
        season_id,
        bowler,
        SUM(balls_bowled) as total_balls,
        SUM(runs_conceded) as total_runs_conceded,
        SUM(wickets) as total_wickets,
        SUM(matches) as total_matches,
        ROUND(SUM(runs_conceded)*1.0 / NULLIF(SUM(wickets), 0), 1) as season_avg,
        ROUND(SUM(runs_conceded)*6.0 / SUM(balls_bowled), 1) as season_economy,
        ROUND(SUM(wickets)*100.0 / (SUM(balls_bowled)/6.0), 1) as season_sr,
        SUM(CASE WHEN wickets >=4 THEN 1 ELSE 0 END) as 4w,
        SUM(CASE WHEN wickets >=5 THEN 1 ELSE 0 END) as 5w,
        MAX(wickets) as best_figures
    FROM yearly_bowler_match_stats ym
    GROUP BY season_id, bowler
    HAVING total_wickets >= 5  -- Quality threshold
)
SELECT * FROM season_summary
ORDER BY season_id DESC, total_wickets DESC;
select * from vw_bowlers_yearly_stats