import 'dart:async';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'em_sdk_method.dart';
import 'models/em_userInfo.dart';

class EMUserInfoManager {
  static const _channelPrefix = 'com.easemob.im';
  static const MethodChannel _channel = const MethodChannel(
      '$_channelPrefix/em_userInfo_manager', JSONMethodCodec());

  EMUserInfo _ownUserInfo;

  //有效的联系人map
  Map<String, EMUserInfo> _effectiveUserInfoMap;

  EMUserInfoManager() {
    _channel.setMethodCallHandler((MethodCall call) {
      return null;
    });

    _effectiveUserInfoMap = Map();
  }

  //更新自己的用户属性
  Future<EMUserInfo> updateOwnUserInfo(EMUserInfo userInfo) async {
    Map req = {'userInfo': userInfo.toJson()};
    Map result =
        await _channel.invokeMethod(EMSDKMethod.updateOwnUserInfo, req);
    EMError.hasErrorFromResult(result);
    print("updateOwnUserInfo_manager result:$result");
    return EMUserInfo.fromJson(result[EMSDKMethod.updateOwnUserInfo]);
  }

  //更新自己制定类型的用户属性
  Future<EMUserInfo> updateOwnUserInfoWithType(
      EMUserInfoType type, String userInfoValue) async {
    Map req = {
      'userInfoType': _userInfoTypeToInt(type),
      'userInfoValue': userInfoValue
    };
    Map result =
        await _channel.invokeMethod(EMSDKMethod.updateOwnUserInfoWithType, req);
    EMError.hasErrorFromResult(result);
    _ownUserInfo =
        EMUserInfo.fromJson(result[EMSDKMethod.updateOwnUserInfoWithType]);
    _ownUserInfo.expireTime = DateTime.now().millisecondsSinceEpoch;
    _effectiveUserInfoMap[_ownUserInfo.userId] = _ownUserInfo;
    return _ownUserInfo;
  }

  Future<EMUserInfo> fetchOwnUserInfo({int expireTime = 60}) async {
    Map<String, EMUserInfo> ret = await fetchUserInfoByIdWithExpireTime(
        [EMClient.getInstance.currentUsername],
        expireTime: expireTime);
    _ownUserInfo = ret.values.first;
    return _ownUserInfo;
  }

  //获取指定id的用户的用户属性
  Future<Map<String, EMUserInfo>> fetchUserInfoByIdWithExpireTime(
      List<String> userIds,
      {int expireTime = 60}) async {
    List<String> reqIds = userIds
        .where((element) =>
            (!_effectiveUserInfoMap.containsKey(element)) ||
            (_effectiveUserInfoMap.containsKey(element) &&
                DateTime.now().millisecondsSinceEpoch -
                        _effectiveUserInfoMap[element].expireTime >
                    expireTime * 1000))
        .toList();

    Map<String, EMUserInfo> resultMap = Map();

    if (reqIds.length == 0) {
      userIds.forEach((element) {
        resultMap[element] = _effectiveUserInfoMap[element];
      });
      return resultMap;
    } else {
      userIds.forEach((element) {
        if (!reqIds.contains(element)) {
          resultMap[element] = _effectiveUserInfoMap[element];
        }
      });
    }

    Map req = {'userIds': reqIds};
    Map result =
        await _channel.invokeMethod(EMSDKMethod.fetchUserInfoById, req);

    EMError.hasErrorFromResult(result);
    result[EMSDKMethod.fetchUserInfoById]?.forEach((key, value) {
      value['expireTime'] = DateTime.now().millisecondsSinceEpoch;
      EMUserInfo eUserInfo = EMUserInfo.fromJson(value);
      resultMap[key] = eUserInfo;
      //restore userInfos
      _effectiveUserInfoMap[key] = eUserInfo;
    });

    return resultMap;
  }

  //获取指定id的用户的指定类型的用户属性
  Future<Map<String, EMUserInfo>> fetchUserInfoByIdWithType(
      List<String> userIds, List<EMUserInfoType> types,
      {int expireTime = 60}) async {
    List<int> userInfoTypes = List();
    types.forEach((element) {
      int type = _userInfoTypeToInt(element);
      userInfoTypes.add(type);
    });

    List<String> reqIds = userIds
        .where((element) =>
            !_effectiveUserInfoMap.containsKey(element) ||
            (_effectiveUserInfoMap.containsKey(element) &&
                DateTime.now().millisecondsSinceEpoch -
                        _effectiveUserInfoMap[element].expireTime >
                    expireTime * 1000))
        .toList();

    Map<String, EMUserInfo> resultMap = Map();
    if (reqIds.length == 0) {
      userIds.forEach((element) {
        resultMap[element] = _effectiveUserInfoMap[element];
      });
      return resultMap;
    } else {
      userIds.forEach((element) {
        if (!reqIds.contains(element)) {
          resultMap[element] = _effectiveUserInfoMap[element];
        }
      });
    }

    Map req = {'userIds': reqIds, 'userInfoTypes': userInfoTypes};
    Map result =
        await _channel.invokeMethod(EMSDKMethod.fetchUserInfoByIdWithType, req);

    EMError.hasErrorFromResult(result);
    result[EMSDKMethod.fetchUserInfoByIdWithType].forEach((key, value) {
      value['expireTime'] = DateTime.now().millisecondsSinceEpoch;
      EMUserInfo eUserInfo = EMUserInfo.fromJson(value);
      resultMap[key] = eUserInfo;
      //restore userInfos
      _effectiveUserInfoMap[key] = eUserInfo;
    });

    return resultMap;
  }

  Future<EMUserInfo> getCurrentUserInfo() async {
    print(
        "EMClient.getInstance.currentUsername:${EMClient.getInstance.currentUsername}");

    Map userInfoMap = await fetchUserInfoByIdWithExpireTime(
        [EMClient.getInstance.currentUsername]);
    EMUserInfo retUseInfo = userInfoMap[EMClient.getInstance.currentUsername];
    print("getCurrentUserInfo userInfoMap:$userInfoMap");
    print("retUseInfo:$retUseInfo");

    return retUseInfo;
  }

  // 整型转化用户属性类型 【int => EMUserInfoType】
  static EMUserInfoType userInfoTypeFromInt(int type) {
    EMUserInfoType ret = EMUserInfoType.EMUserInfoTypeNickName;
    switch (type) {
      case 0:
        {
          ret = EMUserInfoType.EMUserInfoTypeNickName;
        }
        break;
      case 1:
        {
          ret = EMUserInfoType.EMUserInfoTypeAvatarURL;
        }
        break;
      case 2:
        {
          ret = EMUserInfoType.EMUserInfoTypePhone;
        }
        break;
      case 3:
        {
          ret = EMUserInfoType.EMUserInfoTypeMail;
        }
        break;
      case 4:
        {
          ret = EMUserInfoType.EMUserInfoTypeGender;
        }
        break;
      case 5:
        {
          ret = EMUserInfoType.EMUserInfoTypeSign;
        }
        break;
      case 6:
        {
          ret = EMUserInfoType.EMUserInfoTypeBirth;
        }
        break;
      case 7:
        {
          ret = EMUserInfoType.EMUserInfoTypeExt;
        }
    }
    return ret;
  }

  // 用户属性类型转化整型 【EMUserInfoType => int】
  static int _userInfoTypeToInt(EMUserInfoType type) {
    int ret = 0;
    switch (type) {
      case EMUserInfoType.EMUserInfoTypeNickName:
        {
          ret = 0;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeAvatarURL:
        {
          ret = 1;
        }
        break;
      case EMUserInfoType.EMUserInfoTypePhone:
        {
          ret = 2;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeMail:
        {
          ret = 3;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeGender:
        {
          ret = 4;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeSign:
        {
          ret = 5;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeBirth:
        {
          ret = 6;
        }
        break;
      case EMUserInfoType.EMUserInfoTypeExt:
        {
          ret = 7;
        }
    }
    return ret;
  }

  void clearUserInfoCache() {
    _effectiveUserInfoMap?.clear();
  }
}
