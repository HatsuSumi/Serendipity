// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EncounterStatusAdapter extends TypeAdapter<EncounterStatus> {
  @override
  final int typeId = 10;

  @override
  EncounterStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EncounterStatus.missed;
      case 1:
        return EncounterStatus.reencounter;
      case 2:
        return EncounterStatus.met;
      case 3:
        return EncounterStatus.reunion;
      case 4:
        return EncounterStatus.farewell;
      case 5:
        return EncounterStatus.lost;
      default:
        return EncounterStatus.missed;
    }
  }

  @override
  void write(BinaryWriter writer, EncounterStatus obj) {
    switch (obj) {
      case EncounterStatus.missed:
        writer.writeByte(0);
        break;
      case EncounterStatus.reencounter:
        writer.writeByte(1);
        break;
      case EncounterStatus.met:
        writer.writeByte(2);
        break;
      case EncounterStatus.reunion:
        writer.writeByte(3);
        break;
      case EncounterStatus.farewell:
        writer.writeByte(4);
        break;
      case EncounterStatus.lost:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncounterStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmotionIntensityAdapter extends TypeAdapter<EmotionIntensity> {
  @override
  final int typeId = 11;

  @override
  EmotionIntensity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmotionIntensity.barelyFelt;
      case 1:
        return EmotionIntensity.slightlyCared;
      case 2:
        return EmotionIntensity.thoughtOnWayHome;
      case 3:
        return EmotionIntensity.allNight;
      case 4:
        return EmotionIntensity.untilNow;
      default:
        return EmotionIntensity.barelyFelt;
    }
  }

  @override
  void write(BinaryWriter writer, EmotionIntensity obj) {
    switch (obj) {
      case EmotionIntensity.barelyFelt:
        writer.writeByte(0);
        break;
      case EmotionIntensity.slightlyCared:
        writer.writeByte(1);
        break;
      case EmotionIntensity.thoughtOnWayHome:
        writer.writeByte(2);
        break;
      case EmotionIntensity.allNight:
        writer.writeByte(3);
        break;
      case EmotionIntensity.untilNow:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionIntensityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaceTypeAdapter extends TypeAdapter<PlaceType> {
  @override
  final int typeId = 12;

  @override
  PlaceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaceType.subway;
      case 1:
        return PlaceType.bus;
      case 2:
        return PlaceType.train;
      case 3:
        return PlaceType.airport;
      case 4:
        return PlaceType.coffeeShop;
      case 5:
        return PlaceType.restaurant;
      case 6:
        return PlaceType.bar;
      case 7:
        return PlaceType.teaHouse;
      case 8:
        return PlaceType.dessertShop;
      case 9:
        return PlaceType.mall;
      case 10:
        return PlaceType.supermarket;
      case 11:
        return PlaceType.bookstore;
      case 12:
        return PlaceType.park;
      case 13:
        return PlaceType.cinema;
      case 14:
        return PlaceType.museum;
      case 15:
        return PlaceType.artGallery;
      case 16:
        return PlaceType.aquarium;
      case 17:
        return PlaceType.zoo;
      case 18:
        return PlaceType.amusementPark;
      case 19:
        return PlaceType.gym;
      case 20:
        return PlaceType.swimmingPool;
      case 21:
        return PlaceType.stadium;
      case 22:
        return PlaceType.library;
      case 23:
        return PlaceType.school;
      case 24:
        return PlaceType.office;
      case 25:
        return PlaceType.hospital;
      case 26:
        return PlaceType.clinic;
      case 27:
        return PlaceType.hotel;
      case 28:
        return PlaceType.beach;
      case 29:
        return PlaceType.mountain;
      case 30:
        return PlaceType.street;
      case 31:
        return PlaceType.other;
      default:
        return PlaceType.subway;
    }
  }

  @override
  void write(BinaryWriter writer, PlaceType obj) {
    switch (obj) {
      case PlaceType.subway:
        writer.writeByte(0);
        break;
      case PlaceType.bus:
        writer.writeByte(1);
        break;
      case PlaceType.train:
        writer.writeByte(2);
        break;
      case PlaceType.airport:
        writer.writeByte(3);
        break;
      case PlaceType.coffeeShop:
        writer.writeByte(4);
        break;
      case PlaceType.restaurant:
        writer.writeByte(5);
        break;
      case PlaceType.bar:
        writer.writeByte(6);
        break;
      case PlaceType.teaHouse:
        writer.writeByte(7);
        break;
      case PlaceType.dessertShop:
        writer.writeByte(8);
        break;
      case PlaceType.mall:
        writer.writeByte(9);
        break;
      case PlaceType.supermarket:
        writer.writeByte(10);
        break;
      case PlaceType.bookstore:
        writer.writeByte(11);
        break;
      case PlaceType.park:
        writer.writeByte(12);
        break;
      case PlaceType.cinema:
        writer.writeByte(13);
        break;
      case PlaceType.museum:
        writer.writeByte(14);
        break;
      case PlaceType.artGallery:
        writer.writeByte(15);
        break;
      case PlaceType.aquarium:
        writer.writeByte(16);
        break;
      case PlaceType.zoo:
        writer.writeByte(17);
        break;
      case PlaceType.amusementPark:
        writer.writeByte(18);
        break;
      case PlaceType.gym:
        writer.writeByte(19);
        break;
      case PlaceType.swimmingPool:
        writer.writeByte(20);
        break;
      case PlaceType.stadium:
        writer.writeByte(21);
        break;
      case PlaceType.library:
        writer.writeByte(22);
        break;
      case PlaceType.school:
        writer.writeByte(23);
        break;
      case PlaceType.office:
        writer.writeByte(24);
        break;
      case PlaceType.hospital:
        writer.writeByte(25);
        break;
      case PlaceType.clinic:
        writer.writeByte(26);
        break;
      case PlaceType.hotel:
        writer.writeByte(27);
        break;
      case PlaceType.beach:
        writer.writeByte(28);
        break;
      case PlaceType.mountain:
        writer.writeByte(29);
        break;
      case PlaceType.street:
        writer.writeByte(30);
        break;
      case PlaceType.other:
        writer.writeByte(31);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeatherAdapter extends TypeAdapter<Weather> {
  @override
  final int typeId = 13;

  @override
  Weather read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Weather.sunny;
      case 1:
        return Weather.cloudy;
      case 2:
        return Weather.overcast;
      case 3:
        return Weather.drizzle;
      case 4:
        return Weather.lightRain;
      case 5:
        return Weather.moderateRain;
      case 6:
        return Weather.heavyRain;
      case 7:
        return Weather.rainstorm;
      case 8:
        return Weather.freezingRain;
      case 9:
        return Weather.lightSnow;
      case 10:
        return Weather.moderateSnow;
      case 11:
        return Weather.heavySnow;
      case 12:
        return Weather.snowstorm;
      case 13:
        return Weather.sleet;
      case 14:
        return Weather.hail;
      case 15:
        return Weather.mist;
      case 16:
        return Weather.fog;
      case 17:
        return Weather.haze;
      case 18:
        return Weather.dust;
      case 19:
        return Weather.sandstorm;
      case 20:
        return Weather.breeze;
      case 21:
        return Weather.windy;
      case 22:
        return Weather.typhoon;
      case 23:
        return Weather.hurricane;
      case 24:
        return Weather.tornado;
      default:
        return Weather.sunny;
    }
  }

  @override
  void write(BinaryWriter writer, Weather obj) {
    switch (obj) {
      case Weather.sunny:
        writer.writeByte(0);
        break;
      case Weather.cloudy:
        writer.writeByte(1);
        break;
      case Weather.overcast:
        writer.writeByte(2);
        break;
      case Weather.drizzle:
        writer.writeByte(3);
        break;
      case Weather.lightRain:
        writer.writeByte(4);
        break;
      case Weather.moderateRain:
        writer.writeByte(5);
        break;
      case Weather.heavyRain:
        writer.writeByte(6);
        break;
      case Weather.rainstorm:
        writer.writeByte(7);
        break;
      case Weather.freezingRain:
        writer.writeByte(8);
        break;
      case Weather.lightSnow:
        writer.writeByte(9);
        break;
      case Weather.moderateSnow:
        writer.writeByte(10);
        break;
      case Weather.heavySnow:
        writer.writeByte(11);
        break;
      case Weather.snowstorm:
        writer.writeByte(12);
        break;
      case Weather.sleet:
        writer.writeByte(13);
        break;
      case Weather.hail:
        writer.writeByte(14);
        break;
      case Weather.mist:
        writer.writeByte(15);
        break;
      case Weather.fog:
        writer.writeByte(16);
        break;
      case Weather.haze:
        writer.writeByte(17);
        break;
      case Weather.dust:
        writer.writeByte(18);
        break;
      case Weather.sandstorm:
        writer.writeByte(19);
        break;
      case Weather.breeze:
        writer.writeByte(20);
        break;
      case Weather.windy:
        writer.writeByte(21);
        break;
      case Weather.typhoon:
        writer.writeByte(22);
        break;
      case Weather.hurricane:
        writer.writeByte(23);
        break;
      case Weather.tornado:
        writer.writeByte(24);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthProviderAdapter extends TypeAdapter<AuthProvider> {
  @override
  final int typeId = 17;

  @override
  AuthProvider read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuthProvider.email;
      case 1:
        return AuthProvider.phone;
      default:
        return AuthProvider.email;
    }
  }

  @override
  void write(BinaryWriter writer, AuthProvider obj) {
    switch (obj) {
      case AuthProvider.email:
        writer.writeByte(0);
        break;
      case AuthProvider.phone:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MembershipTierAdapter extends TypeAdapter<MembershipTier> {
  @override
  final int typeId = 18;

  @override
  MembershipTier read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MembershipTier.free;
      case 1:
        return MembershipTier.premium;
      default:
        return MembershipTier.free;
    }
  }

  @override
  void write(BinaryWriter writer, MembershipTier obj) {
    switch (obj) {
      case MembershipTier.free:
        writer.writeByte(0);
        break;
      case MembershipTier.premium:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MembershipStatusAdapter extends TypeAdapter<MembershipStatus> {
  @override
  final int typeId = 19;

  @override
  MembershipStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MembershipStatus.inactive;
      case 1:
        return MembershipStatus.active;
      case 2:
        return MembershipStatus.expired;
      case 3:
        return MembershipStatus.cancelled;
      default:
        return MembershipStatus.inactive;
    }
  }

  @override
  void write(BinaryWriter writer, MembershipStatus obj) {
    switch (obj) {
      case MembershipStatus.inactive:
        writer.writeByte(0);
        break;
      case MembershipStatus.active:
        writer.writeByte(1);
        break;
      case MembershipStatus.expired:
        writer.writeByte(2);
        break;
      case MembershipStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 20;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.free;
      case 1:
        return PaymentMethod.applePay;
      case 2:
        return PaymentMethod.googlePay;
      case 3:
        return PaymentMethod.alipay;
      case 4:
        return PaymentMethod.wechatPay;
      default:
        return PaymentMethod.free;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.free:
        writer.writeByte(0);
        break;
      case PaymentMethod.applePay:
        writer.writeByte(1);
        break;
      case PaymentMethod.googlePay:
        writer.writeByte(2);
        break;
      case PaymentMethod.alipay:
        writer.writeByte(3);
        break;
      case PaymentMethod.wechatPay:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 21;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.pending;
      case 1:
        return PaymentStatus.processing;
      case 2:
        return PaymentStatus.success;
      case 3:
        return PaymentStatus.failed;
      case 4:
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.pending:
        writer.writeByte(0);
        break;
      case PaymentStatus.processing:
        writer.writeByte(1);
        break;
      case PaymentStatus.success:
        writer.writeByte(2);
        break;
      case PaymentStatus.failed:
        writer.writeByte(3);
        break;
      case PaymentStatus.refunded:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemeOptionAdapter extends TypeAdapter<ThemeOption> {
  @override
  final int typeId = 22;

  @override
  ThemeOption read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ThemeOption.light;
      case 1:
        return ThemeOption.dark;
      case 2:
        return ThemeOption.system;
      case 3:
        return ThemeOption.misty;
      case 4:
        return ThemeOption.midnight;
      case 5:
        return ThemeOption.warm;
      case 6:
        return ThemeOption.autumn;
      default:
        return ThemeOption.light;
    }
  }

  @override
  void write(BinaryWriter writer, ThemeOption obj) {
    switch (obj) {
      case ThemeOption.light:
        writer.writeByte(0);
        break;
      case ThemeOption.dark:
        writer.writeByte(1);
        break;
      case ThemeOption.system:
        writer.writeByte(2);
        break;
      case ThemeOption.misty:
        writer.writeByte(3);
        break;
      case ThemeOption.midnight:
        writer.writeByte(4);
        break;
      case ThemeOption.warm:
        writer.writeByte(5);
        break;
      case ThemeOption.autumn:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageTransitionTypeAdapter extends TypeAdapter<PageTransitionType> {
  @override
  final int typeId = 24;

  @override
  PageTransitionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PageTransitionType.none;
      case 1:
        return PageTransitionType.random;
      case 2:
        return PageTransitionType.slideFromRight;
      case 3:
        return PageTransitionType.slideFromBottom;
      case 4:
        return PageTransitionType.slideFromLeft;
      case 5:
        return PageTransitionType.slideFromTop;
      case 6:
        return PageTransitionType.fade;
      case 7:
        return PageTransitionType.scale;
      case 8:
        return PageTransitionType.rotation;
      default:
        return PageTransitionType.none;
    }
  }

  @override
  void write(BinaryWriter writer, PageTransitionType obj) {
    switch (obj) {
      case PageTransitionType.none:
        writer.writeByte(0);
        break;
      case PageTransitionType.random:
        writer.writeByte(1);
        break;
      case PageTransitionType.slideFromRight:
        writer.writeByte(2);
        break;
      case PageTransitionType.slideFromBottom:
        writer.writeByte(3);
        break;
      case PageTransitionType.slideFromLeft:
        writer.writeByte(4);
        break;
      case PageTransitionType.slideFromTop:
        writer.writeByte(5);
        break;
      case PageTransitionType.fade:
        writer.writeByte(6);
        break;
      case PageTransitionType.scale:
        writer.writeByte(7);
        break;
      case PageTransitionType.rotation:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageTransitionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DialogAnimationTypeAdapter extends TypeAdapter<DialogAnimationType> {
  @override
  final int typeId = 25;

  @override
  DialogAnimationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DialogAnimationType.none;
      case 1:
        return DialogAnimationType.random;
      case 2:
        return DialogAnimationType.fade;
      case 3:
        return DialogAnimationType.scale;
      case 4:
        return DialogAnimationType.slideUp;
      case 5:
        return DialogAnimationType.slideDown;
      case 6:
        return DialogAnimationType.slideLeft;
      case 7:
        return DialogAnimationType.slideRight;
      case 8:
        return DialogAnimationType.fadeScale;
      case 9:
        return DialogAnimationType.fadeSlide;
      default:
        return DialogAnimationType.none;
    }
  }

  @override
  void write(BinaryWriter writer, DialogAnimationType obj) {
    switch (obj) {
      case DialogAnimationType.none:
        writer.writeByte(0);
        break;
      case DialogAnimationType.random:
        writer.writeByte(1);
        break;
      case DialogAnimationType.fade:
        writer.writeByte(2);
        break;
      case DialogAnimationType.scale:
        writer.writeByte(3);
        break;
      case DialogAnimationType.slideUp:
        writer.writeByte(4);
        break;
      case DialogAnimationType.slideDown:
        writer.writeByte(5);
        break;
      case DialogAnimationType.slideLeft:
        writer.writeByte(6);
        break;
      case DialogAnimationType.slideRight:
        writer.writeByte(7);
        break;
      case DialogAnimationType.fadeScale:
        writer.writeByte(8);
        break;
      case DialogAnimationType.fadeSlide:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogAnimationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
