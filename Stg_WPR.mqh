/**
 * @file
 * Implements WPR strategy based on the Larry Williams' Percent Range indicator.
 */

// User input params.
INPUT string __WPR_Parameters__ = "-- WPR strategy params --";  // >>> WPR <<<
INPUT float WPR_LotSize = 0;                                    // Lot size
INPUT int WPR_SignalOpenMethod = 0;                             // Signal open method (-7-7)
INPUT float WPR_SignalOpenLevel = 20;                           // Signal open level
INPUT int WPR_SignalOpenFilterMethod = 1;                       // Signal open filter method
INPUT int WPR_SignalOpenBoostMethod = 0;                        // Signal open boost method
INPUT int WPR_SignalCloseMethod = 0;                            // Signal close method (-7-7)
INPUT float WPR_SignalCloseLevel = 20;                          // Signal close level
INPUT int WPR_PriceStopMethod = 0;                              // Price stop method
INPUT float WPR_PriceStopLevel = 0;                             // Price stop level
INPUT int WPR_TickFilterMethod = 1;                             // Tick filter method
INPUT float WPR_MaxSpread = 4.0;                                // Max spread to trade (pips)
INPUT int WPR_Shift = 0;                                        // Shift
INPUT int WPR_OrderCloseTime = -20;                             // Order close time in mins (>0) or bars (<0)
INPUT string __WPR_Indi_WPR_Parameters__ =
    "-- WPR strategy: WPR indicator params --";  // >>> WPR strategy: WPR indicator <<<
INPUT int WPR_Indi_WPR_Period = 14;              // Period
INPUT int WPR_Indi_WPR_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_WPR_Params_Defaults : WPRParams {
  Indi_WPR_Params_Defaults() : WPRParams(::WPR_Indi_WPR_Period, ::WPR_Indi_WPR_Shift) {}
} indi_wpr_defaults;

// Defines struct with default user strategy values.
struct Stg_WPR_Params_Defaults : StgParams {
  Stg_WPR_Params_Defaults()
      : StgParams(::WPR_SignalOpenMethod, ::WPR_SignalOpenFilterMethod, ::WPR_SignalOpenLevel,
                  ::WPR_SignalOpenBoostMethod, ::WPR_SignalCloseMethod, ::WPR_SignalCloseLevel, ::WPR_PriceStopMethod,
                  ::WPR_PriceStopLevel, ::WPR_TickFilterMethod, ::WPR_MaxSpread, ::WPR_Shift, ::WPR_OrderCloseTime) {}
} stg_wpr_defaults;

// Struct to define strategy parameters to override.
struct Stg_WPR_Params : StgParams {
  WPRParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_WPR_Params(WPRParams &_iparams, StgParams &_sparams)
      : iparams(indi_wpr_defaults, _iparams.tf), sparams(stg_wpr_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_WPR : public Strategy {
 public:
  Stg_WPR(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_WPR *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    WPRParams _indi_params(indi_wpr_defaults, _tf);
    StgParams _stg_params(stg_wpr_defaults);
#ifdef __config__
    SetParamsByTf<WPRParams>(_indi_params, _tf, indi_wpr_m1, indi_wpr_m5, indi_wpr_m15, indi_wpr_m30, indi_wpr_h1,
                             indi_wpr_h4, indi_wpr_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_wpr_m1, stg_wpr_m5, stg_wpr_m15, stg_wpr_m30, stg_wpr_h1, stg_wpr_h4,
                             stg_wpr_h8);
#endif
    // Initialize indicator.
    WPRParams wpr_params(_indi_params);
    _stg_params.SetIndicator(new Indi_WPR(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_WPR(_stg_params, "WPR");
    return _strat;
  }

  /**
   * Check if WPR indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_WPR *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      double level = -50 - _level * Order::OrderDirection(_cmd);
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: Value below level.
          _result &= _indi[PREV][0] < level || _indi[PPREV][0] < level;
          _result &= _indi.IsIncreasing(2);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(3);
            // Buy: crossing level upwards.
            if (METHOD(_method, 1)) _result &= _indi[PPREV][0] > level || _indi[PREV][0] > level;
            if (METHOD(_method, 2)) _result &= _indi[PREV][0] - _indi[CURR][0] > _indi[PPREV][0] - _indi[PREV][0];
          }
          /* @todo
             //30. Williams Percent Range
             if (iWPR(NULL,piwpr,piwprbar,1)<-80&&iWPR(NULL,piwpr,piwprbar,0)>=-80)
             {f30=1;}
             if (iWPR(NULL,piwpr,piwprbar,1)>-20&&iWPR(NULL,piwpr,piwprbar,0)<=-20)
             {f30=-1;}
          */
          break;
        case ORDER_TYPE_SELL:
          // Sell: Value above level.
          _result &= _indi[PREV][0] > level || _indi[PPREV][0] > level;
          _result &= _indi.IsDecreasing(2);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(3);
            // Sell: crossing level downwards.
            if (METHOD(_method, 1)) _result &= _indi[PPREV][0] < level || _indi[PREV][0] < level;
            if (METHOD(_method, 2)) _result &= _indi[CURR][0] - _indi[PREV][0] > _indi[PREV][0] - _indi[PPREV][0];
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_WPR *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1: {
          int _bar_count0 = (int)_level * (int)_indi.GetPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count0));
          break;
        }
        case 2: {
          int _bar_count1 = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
