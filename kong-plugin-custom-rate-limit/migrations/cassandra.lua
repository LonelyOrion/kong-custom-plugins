return {
  {
    name = "2018-01-22-132400_init_custom-rate-limit",
    up = [[
      CREATE TABLE IF NOT EXISTS ratelimiting_metrics(
        api_id uuid,
        identifier text,
        period text,
        period_date timestamp,
        value counter,
        PRIMARY KEY ((api_id, identifier, period_date, period))
      );
    ]],
    down = [[
      DROP TABLE ratelimiting_metrics;
    ]]
  },
  {
    name = "2018-01-22-471385_custom-rate-limit_policies",
    up = function(_, _, dao)
      local rows, err = dao.plugins:find_all {name = "custom-rate-limit"}
      if err then
        return err
      end

      for i = 1, #rows do
        local rate_limiting = rows[i]

        -- Delete the old one to avoid conflicts when inserting the new one
        local _, err = dao.plugins:delete(rate_limiting)
        if err then
          return err
        end

        local _, err = dao.plugins:insert {
          name = "custom-rate-limit",
          api_id = rate_limiting.api_id,
          consumer_id = rate_limiting.consumer_id,
          enabled = rate_limiting.enabled,
          config = {
            second = rate_limiting.config.second,
            minute = rate_limiting.config.minute,
            hour = rate_limiting.config.hour,
            day = rate_limiting.config.day,
            month = rate_limiting.config.month,
            year = rate_limiting.config.year,
            limit_by = "consumer",
            policy = "cluster",
            fault_tolerant = rate_limiting.config.continue_on_error
          }
        }
        if err then
          return err
        end
      end
    end
  }
}
