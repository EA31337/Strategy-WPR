/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_WPR_Params_M30 : WPRParams {
  Indi_WPR_Params_M30() : WPRParams(indi_wpr_defaults, PERIOD_M30) {
    period = 8;
    shift = 0;
  }
} indi_wpr_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_WPR_Params_M30 : StgParams {
  // Struct constructor.
  Stg_WPR_Params_M30() : StgParams(stg_wpr_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)20.0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)1;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_wpr_m30;
