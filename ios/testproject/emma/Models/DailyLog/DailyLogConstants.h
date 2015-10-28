//
//  DailyLogConstants.h
//  emma
//
//  Created by Xin Zhao on 13-9-18.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#ifndef emma_DailyLogConstants_h
#define emma_DailyLogConstants_h

#define DAILY_LOG_VAL_NONE 0
#define DAILY_LOG_VAL_NO   1
#define DAILY_LOG_VAL_YES  2

/* Migration */
#define DL_MOOD_NEGATIVE_STRESSED 0x40
#define DL_DEFAULT_STRESS 50
#define MOODS_NAME @{\
@16: @"sad",\
@32: @"angry",\
@64: @"stressed",\
@128: @"moody",\
@256: @"anxious"}
#define PHYSICAL_DISCOMFORT_NAME @{\
@16: @"migraine",\
@32: @"cramps",\
@64: @"GI pain",\
@128: @"sore breasts",\
@512: @"pain during sex",\
@1024: @"fatigue",\
@2048: @"vaginal pain",\
@4096: @"nausea",\
@8192: @"bloating",\
@16384: @"backache"}


/* Period
 
 */
#define LOG_VAL_PERIOD_BEGAN 1
#define LOG_VAL_PERIOD_ENDED 3

#define ARCHIVED_PERIOD_SHIFT 4
#define CURRENT_PERIOD_MOD_BASE 4
#define DEFAULT_PL 5

/* BBT
 
 if given, in Celsius
 if not given,  None or 0
 */
#define DAILY_LOG_ITEM_BBT  @"temperature"

/* Performed CM check
 
 if not give       0
 if select no      1
 if select yes
 CM_TEXTURE_XX(option) + CM_WETNESS << 8
 there is a bug, if we only select "Yes"
 5 + 5 << 8 = 1285
 0 + 5 << 8 = 1280
 both of them are correct number
 */
#define DAILY_LOG_ITEM_CERVICAL_MUCUS @"cervicalMucus"
#define CM_SELECT_NO    DAILY_LOG_VAL_NO   // 1
#define CM_NOT_SELECTED 5
// CM_TEXTURE_XX
#define CM_TEXTURE_NO       CM_NOT_SELECTED
#define CM_TEXTURE_DRY      10
#define CM_TEXTURE_STICKY   50
#define CM_TEXTURE_WATERY   65
#define CM_TEXTURE_EGGWHITE 80
#define CM_TEXTURE_CREAMY   90
// CM_WETNESS
#define CM_WETNESS_NO   CM_NOT_SELECTED
#define CM_WETNESS_DRY  10
#define CM_WETNESS_DAMP 50
#define CM_WETNESS_WET  90

/* Did you have sex
 
 if not give       0
 if select no      1
 if select yes     2 + x
 INTERCOURSE_NORMAL + POSITION(option) + ORGASM(option)
 */
#define DAILY_LOG_ITEM_INTERCOURSE @"intercourse"
#define INTERCOURSE_NO                  1
#define INTERCOURSE_NORMAL              2
#define INTERCOURSE_WITHOUT_PROTECTION  524290
#define INTERCOURSE_ORGASM_YES          0x10
#define INTERCOURSE_ORGASM_NO           0x20
#define INTERCOURSE_POSITION_ONBOTTOM   0x100
#define INTERCOURSE_POSITION_INFRONT    0x200
#define INTERCOURSE_POSITION_ONTOP      0x400
#define INTERCOURSE_POSITION_OTHER      0x800

#define BIRTH_CONTROL_PILL               0x1000
#define BIRTH_CONTROL_CONDOM             0x2000
#define BIRTH_CONTROL_WITHDRAWAL         0x4000
#define BIRTH_CONTROL_DIAPHRAGM          0x8000
#define BIRTH_CONTROL_COMBO              0x10000
#define BIRTH_CONTROL_OTHER              0x20000
#define BIRTH_CONTROL_MORNING_AFTER_PILL 0x40000
#define BIRTH_CONTROL_NONE               0x80000

#define INTERCOURSE_LUBRICANT_NONE      0x100000
#define INTERCOURSE_LUBRICANT_SILICON   0x200000
#define INTERCOURSE_LUBRICANT_WATER     0x400000
#define INTERCOURSE_LUBRICANT_OIL       0x800000
#define INTERCOURSE_LUBRICANT_OTHER     0x1000000
/* Ovulation test
 
 if not given    0
 if given
 OV_TESTKIT + OV_TEST_YES/NO/HIGH (option)
 */
#define DAILY_LOG_ITEM_OVTEST @"ovulationTest"
#define OVULATION_TEST_YES   1
#define OVULATION_TEST_NO    2
#define OVULATION_TEST_HIGH  3
#define OVULATION_TESTKIT_BRAND_CLEARBLUE_DIGITAL     10
#define OVULATION_TESTKIT_BRAND_CLEARBLUE_EASY_READ   20
#define OVULATION_TESTKIT_BRAND_FIRSTRESPONSE_DIGITAL 30
#define OVULATION_TESTKIT_BRAND_FIRSTRESPONSE_FERTILITY 40
#define OVULATION_TESTKIT_BRAND_OTHER 50

/* Cervical position
 
 if not given    0
 if given
 (high/median/low    of POSITION_HEIGHT) << 4 +
 (open/median/closed of POSITION_OPENNESS) << 8 +
 (soft/median/firm   of POSITION_FIRMNESS) << 12
 */
#define DAILY_LOG_ITEM_CERVICAL_POSITION @"cervical"
#define CERVICAL_POSITION_HIGH    1
#define CERVICAL_POSITION_MEDIAN  2
#define CERVICAL_POSITION_LOW     3
#define CERVICAL_POSITION_HEIGHT    4
#define CERVICAL_POSITION_OPENNESS  8
#define CERVICAL_POSITION_FIRMNESS  12

/* Sleep duration
 
 if not given    0
 if given, seconds of sleep
 */
#define DAILY_LOG_ITEM_SLEEP @"sleep"

/* Spotting (period flow)
 
 if not given     0
 if select no     1
 if select yes
 SPOTTING_YES  + PERIOD_FLOW(option)
 */
#define DAILY_LOG_ITEM_SPOTTING @"periodFlow"
#define SPOTTING_NO    DAILY_LOG_VAL_NO     // 1
#define SPOTTING_YES   DAILY_LOG_VAL_YES    // 2
#define PERIOD_FLOW_SPOTTING 0x8
#define PERIOD_FLOW_LOW     0x10
#define PERIOD_FLOW_MEDIUM  0x40
#define PERIOD_FLOW_HEAVY   0x80

/* Did you exercise
 
 if not given     0
 if select no     1
 if select yes
 SPOTTING_YES  or PERIOD_FLOW(option)
 
 NOTE: if the user select exercise light, the value is 4, not 4+2=6
 */
#define DAILY_LOG_ITEM_EXERCISE @"exercise"
#define EXERCISE_NO    DAILY_LOG_VAL_NO     // 1
#define EXERCISE_YES   DAILY_LOG_VAL_YES    // 2
#define EXERCISE_LIGHTLY     0x4
#define EXERCISE_ACTIVE      0x8
#define EXERCISE_VERY_ACTIVE 0x10
#define EXERCISE_SEDENTARY   0x20
#define EXERCISE_SLIGHTLY    0x40

/* Update weight
 
 if not given     0
 if given, in kg
 */
#define DAILY_LOG_ITEM_WEIGHT @"weight"

#define FROM_MFP_FLAT_WEIGHT 0x1

/* Emotions
 
 */
#define DAILY_LOG_ITEM_EMOTION_SYMPTOM @"moods"
#define EMOTIONAL_SYMPTOM_ONE_KEY @"emotionalSymptom1"
#define EMOTIONAL_SYMPTOM_TWO_KEY @"emotionalSymptom2"

typedef NS_ENUM(uint64_t, EmotionalSymptomType) {
    // emotional_symptom_1,
    EmotionalSymptomAngry      = 0,
    EmotionalSymptomAnxious    = 4,
    EmotionalSymptomCalm       = 8,
    EmotionalSymptomDepressed  = 12,
    EmotionalSymptomEmotional  = 16,
    EmotionalSymptomEnergetic  = 20,
    EmotionalSymptomExcited    = 24,
    EmotionalSymptomFocused    = 28,
    EmotionalSymptomFrustrated = 32,
    EmotionalSymptomFrisky     = 36,
    EmotionalSymptomHappy      = 40,
    EmotionalSymptomInLove     = 44,
    EmotionalSymptomIrritable  = 48,
    EmotionalSymptomMoody      = 52,
    EmotionalSymptomMotivated  = 56,
    
    // EmotionalSymptom2,
    EmotionalSymptomNeutral    = 64,
    EmotionalSymptomSad        = 68,
    EmotionalSymptomSensitive  = 72,
    EmotionalSymptomTired      = 76
};


#define EmotionalSymptomFieldOne @[@(0), @(4), @(8), @(12), @(16), @(20), @(24), @(28), @(32), @(36), @(40), @(44), @(48), @(52), @(56)]
#define EmotionalSymptomFieldTwo @[@(64), @(68), @(72), @(76)]

#define EmotionalSymptomNames @{\
@(EmotionalSymptomAngry)      : @"Angry",\
@(EmotionalSymptomAnxious)    : @"Anxious",\
@(EmotionalSymptomCalm)       : @"Calm",\
@(EmotionalSymptomDepressed)  : @"Depressed",\
@(EmotionalSymptomEmotional)  : @"Emotional",\
@(EmotionalSymptomEnergetic)  : @"Energetic",\
@(EmotionalSymptomExcited)    : @"Excited",\
@(EmotionalSymptomFocused)    : @"Focused",\
@(EmotionalSymptomFrustrated) : @"Frustrated",\
@(EmotionalSymptomFrisky)     : @"Frisky",\
@(EmotionalSymptomHappy)      : @"Happy",\
@(EmotionalSymptomInLove)     : @"In love",\
@(EmotionalSymptomIrritable)  : @"Irritable",\
@(EmotionalSymptomMoody)      : @"Moody",\
@(EmotionalSymptomMotivated)  : @"Motivated",\
@(EmotionalSymptomNeutral)    : @"Neutral",\
@(EmotionalSymptomSad)        : @"Sad",\
@(EmotionalSymptomSensitive)  : @"Sensitive",\
@(EmotionalSymptomTired)      : @"Tired"\
}


/* Feel stressed
 
 if not given     0
 if select no     1
 if select yes
 STRESS_LEVEL_YES + (1-100)
 */
#define DAILY_LOG_ITEM_STRESS_LEVEL @"stressLevel"
#define STRESS_LEVEL_NO   DAILY_LOG_VAL_NO     // 1
#define STRESS_LEVEL_YES  DAILY_LOG_VAL_YES    // 2


/* Physical symptoms
 
 */
#define DAILY_LOG_ITEM_PHYSICAL_SYMPTOM @"physicalDiscomfort"
#define PHYSICAL_SYMPTOM_ONE_KEY @"physicalSymptom1"
#define PHYSICAL_SYMPTOM_TWO_KEY @"physicalSymptom2"

typedef NS_ENUM(NSUInteger, SymptomField) {
    SymptomFieldOne = 1,
    SymptomFieldTwo = 2
};


typedef NS_ENUM(uint64_t, SymptomType) {
    SymptomTypePhysical = 0,
    SymptomTypeEmotional = 1
};


typedef NS_ENUM(uint64_t, SymptomIntensity) {
    SymptomIntensityNone = 0,
    SymptomIntensityMild = 1,
    SymptomIntensityModerate = 2,
    SymptomIntensitySevere = 3
};

typedef NS_ENUM(uint64_t, PhysicalSymptomType) {
    // Physicalsymptom1
    PhysicalSymptomAcne         = 0,
    PhysicalSymptomAppetite     = 4,
    PhysicalSymptomBackache     = 8,
    PhysicalSymptomBloating     = 12,
    PhysicalSymptomConstipation = 16,
    PhysicalSymptomCramps       = 20,
    PhysicalSymptomDiarrhea     = 24,
    PhysicalSymptomDizziness    = 28,
    PhysicalSymptomFatigue      = 32,
    PhysicalSymptomHeadache     = 36,
    PhysicalSymptomHotFlashes   = 40,
    PhysicalSymptomIndigestion  = 44,
    PhysicalSymptomInsomnia     = 48,
    PhysicalSymptomMigraine     = 52,
    PhysicalSymptomNausea       = 56,
    
    // PhysicalSymptom2,
    PhysicalSymptomPainDuringSex    = 64,
    PhysicalSymptomPelvicPain       = 68,
    PhysicalSymptomSexDrive         = 72,
    PhysicalSymptomSick             = 76,
    PhysicalSymptomSoreBreasts      = 80,
    PhysicalSymptomVaginalPain      = 84,
    PhysicalSymptomGroinInjury      = 88,
    PhysicalSymptomPrematureEjaculation = 92
};


#define PhysicalSymptomFieldOne @[@(0), @(4), @(8), @(12), @(16), @(20), @(24), @(28), @(32), @(36), @(40), @(44), @(48), @(52), @(56)]
#define PhysicalSymptomFieldTwo @[@(64), @(68), @(72), @(76), @(80), @(84), @(88), @(92)]

#define PhysicalSymptomNames @{\
@(PhysicalSymptomAcne)         : @"Acne",\
@(PhysicalSymptomAppetite)     : @"Appetite",\
@(PhysicalSymptomBackache)     : @"Backache",\
@(PhysicalSymptomBloating)     : @"Bloating",\
@(PhysicalSymptomConstipation) : @"Constipation",\
@(PhysicalSymptomCramps)       : @"Cramps",\
@(PhysicalSymptomDiarrhea)     : @"Diarrhea",\
@(PhysicalSymptomDizziness)    : @"Dizziness",\
@(PhysicalSymptomFatigue)      : @"Fatigue",\
@(PhysicalSymptomHeadache)     : @"Headache",\
@(PhysicalSymptomHotFlashes)   : @"Hot flashes",\
@(PhysicalSymptomIndigestion)  : @"Indigestion",\
@(PhysicalSymptomInsomnia)     : @"Insomnia",\
@(PhysicalSymptomMigraine)     : @"Migraine",\
@(PhysicalSymptomNausea)       : @"Nausea",\
@(PhysicalSymptomPainDuringSex): @"Pain during sex",\
@(PhysicalSymptomPelvicPain)   : @"Pelvic pain",\
@(PhysicalSymptomSexDrive)     : @"Sex drive",\
@(PhysicalSymptomSick)         : @"Sick",\
@(PhysicalSymptomSoreBreasts)  : @"Sore breasts",\
@(PhysicalSymptomVaginalPain)  : @"Vaginal pain"\
}

#define PhysicalSymptomNamesForMale @{\
@(PhysicalSymptomAcne)         : @"Acne",\
@(PhysicalSymptomBackache)     : @"Backache",\
@(PhysicalSymptomConstipation) : @"Constipation",\
@(PhysicalSymptomDiarrhea)     : @"Diarrhea",\
@(PhysicalSymptomFatigue)      : @"Fatigue",\
@(PhysicalSymptomHeadache)     : @"Headache",\
@(PhysicalSymptomGroinInjury)  : @"Injury to groin area",\
@(PhysicalSymptomIndigestion)  : @"Indigestion",\
@(PhysicalSymptomInsomnia)     : @"Insomnia",\
@(PhysicalSymptomPainDuringSex): @"Pain during sex",\
@(PhysicalSymptomPrematureEjaculation): @"Premature ejaculation",\
@(PhysicalSymptomSexDrive)     : @"Sex drive",\
@(PhysicalSymptomSick)         : @"Sick"\
}


/* Did you smoke
 
 if not given     0
 if select no     1
 if select yes
 SMOKE_YES + (1-20)
 */
#define DAILY_LOG_ITEM_SMOKE @"smoke"
#define SMOKE_NO   DAILY_LOG_VAL_NO     // 1
#define SMOKE_YES  DAILY_LOG_VAL_YES    // 2

/* Did you drink alcohol
 
 if not given     0
 if select no     1
 if select yes
 ALCOHOL_YES + (1-10)
 */
#define DAILY_LOG_ITEM_ALCOHOL @"alcohol"
#define ALCOHOL_NO   DAILY_LOG_VAL_NO     // 1
#define ALCOHOL_YES  DAILY_LOG_VAL_YES    // 2


/* Pregnancy test
 
 if not given    0
 if given
 PREGNANCY_TESTKIT + PREGNANCY_TEST_YES/NO/HIGH (option)
 */
#define DAILY_LOG_ITEM_PREGNANCY_TEST @"pregnancyTest"
#define PREGNANCY_TEST_YES = 0x1
#define PREGNANCY_TEST_NO  = 0x2
#define PREGNANCY_TESTKIT_BRAND_CLEARBLUE_DIGITAL        10
#define PREGNANCY_TESTKIT_BRAND_CLEARBLUE_EASY_READ      20
#define PREGNANCY_TESTKIT_BRAND_FIRSTRESPONSE_DIGITAL    30
#define PREGNANCY_TESTKIT_BRAND_FIRSTRESPONSE_FERTILITY  40
#define PREGNANCY_TESTKIT_BRAND_OTHER                    50

/* medication
 */
#define DAILY_LOG_ITEM_MEDICATION @"meds"


/* Did you have trouble with erection
 
 */
#define DAILY_LOG_ITEM_ERECTION @"erection"
#define ERECTION_NO_TROUBLE 1
#define ERECTION_HAS_TROUBLE 2

/* Did you masturbate
 
 */
#define DAILY_LOG_ITEM_MASTURBATION @"masturbation"
#define MASTURBATE_NO           1
#define MASTURBATE_YES          2
#define MASTURBATE_ONCE         0x10
#define MASTURBATE_TWICE        0x20
#define MASTURBATE_MORE         0x40

/* Were you exposed to any direct heat sources
 
 */
#define DAILY_LOG_ITEM_HEAT_SOURCE @"heatSource"
#define EXPOSE_TO_HEAT_NO                1
#define EXPOSE_TO_HEAT_YES               2
#define EXPOSE_TO_HEAT_HOT_BATH          0x10
#define EXPOSE_TO_HEAT_SAUNAS            0x20
#define EXPOSE_TO_HEAT_ELECTRIC_BLANKET  0x40
#define EXPOSE_TO_HEAT_OTHER             0x80

/* Do you have a fever?
 
 */
#define DAILY_LOG_ITEM_FEVER @"fever"
#define FEVER_NO                  1
#define FEVER_YES                 2
#define FEVER_ONE_DAY             0x10
#define FEVER_TWO_DAYS            0x20
#define FEVER_THREE_PLUS_DAYS     0x40
#endif
