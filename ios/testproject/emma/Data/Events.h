//
//  Header.h
//  emma
//
//  Created by Xin Zhao on 13-5-7.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#ifndef emma_Events_h
#define emma_Events_h

//app events
#define EVENT_APP_IDLE @"app_idle" //send when specified time elapsed after last user touch
#define EVENT_USER_REMOVED_FROM_SERVER @"user_removed_from_server"
#define EVENT_TOKEN_EXPIRED @"token_expired"
#define EVENT_PROFILE_MODIFIED @"event_profile_modified"
#define EVENT_HOME_GOTO_TODAY @"event_home_goto_today"
#define EVENT_USER_STATUS_HISTORY_CHANGED @"event_user_status_history_changed"

// tutorials
#define EVENT_TUTORIAL_ENTER_STEP1 @"tutorial_enter_step1"
#define EVENT_TUTORIAL_ENTER_STEP2 @"tutorial_enter_step2"
#define EVENT_TUTORIAL_ENTER_STEP3 @"tutorial_enter_step3"
#define EVENT_TUTORIAL_ENTER_STEP4 @"tutorial_enter_step4"
#define EVENT_TUTORIAL_START_LOGGING @"tutorial_start_logging"

// home
#define EVENT_HOME_VIEW_APPEAR @"event_home_view_appear"
#define EVENT_SWITCHED_TO_FULL_CALENDAR @"event_switched_to_full_calendar"
#define EVENT_SWITCHED_TO_TINY_CALENDAR @"event_switched_to_tiny_calendar"
#define EVENT_HOME_GO_TO_TOPIC @"event_home_go_to_topic"
#define EVENT_HOME_GO_TO_REPLY @"event_home_go_to_reply"
#define EVENT_HOME_CARD_CUSTOMIZATION_UPDATED @"event_home_card_customization_updated"
#define EVENT_FORCE_REGENERATE_TODAYS_DAILY_CONTENT @"event_force_regenerate_todays_daily_content"

//daily log
#define EVENT_DAILY_LOG_SAVED @"daily_log_saved"
#define EVENT_DAILY_LOG_EXIT @"daily_log_exit"
#define EVENT_USERDAILYDATA_UPDATED_FROM_SERVER @"userdailydata_updated_from_server"
#define EVENT_DAILY_LOG_PREGNANT @"daily_log_pregnant"

#define EVENT_USER_CLK_PREGNANT @"fund_user_click_pregnant"
#define EVENT_MEDICINE_RETURNED @"medicine_returned"
#define EVENT_DAILY_DATA_UPDATE_TO_CAL_ANIME @"daily_data_update_to_cal_anime"
#define EVENT_DAILY_LOG_UNIT_CHANGED @"daily_log_unit_changed"

// Medical Log
#define EVENT_MEDICAL_LOG_SAVED @"medical_log_saved"
#define EVENT_MEDICALLOG_UPDATED_FROM_SERVER @"medicallog_updated_from_server"

// daily log, temperature input keyboard
#define EVENT_KBINPUT_DONE @"eventKBInputDone"
#define EVENT_KBINPUT_CANCEL @"eventKBInputCancel"
#define EVENT_KBINPUT_STARTOVER @"eventKBInputStartOver"
#define EVENT_KEYBOARD_DISMISSED @"KeyboardDismissed"
#define EVENT_KBINPUT_UNIT_SWITCH @"eventKBUnitSwitch"

// daily notes
#define EVENT_DAILY_NOTES_UPDATED @"event_daily_notes_updated"
#define EVENT_NOTE_EDIT_SCROLL_PAGE @"event_note_edit_scroll_page"

//prediction events
#define EVENT_PREDICTION_UPDATE @"prediction_update"

//notifications
#define EVENT_NOTIFICATION_HIDDEN @"event_notification_hidden"
#define EVENT_NOTIFICATION_UPDATED @"event_notification_updated"
#define EVENT_GO_SET_BBT_REMINDER @"event_go_set_bbt_reminder"
#define EVENT_NOTIF_GO_GLOW_FIRST @"event_notif_go_glow_first"
#define EVENT_NOTIF_GO_REMINDER @"event_notif_go_reminder"
#define EVENT_NOTIF_GO_PROMO @"event_notif_go_promo"
#define EVENT_NOTIF_GO_PERIOD @"event_notif_go_period"
#define EVENT_NOTIF_REFILL_BY_SCAN @"event_notif_refill_by_scan"
#define EVENT_NOTIF_GO_DAILY_LOG @"event_notif_go_daily_log"

//tutorial
#define EVENT_TUTORIAL_COMPLETED @"tutorial_completed"
#define EVENT_TUTORIAL_DID_START @"tutorial_did_start"

#define EVENT_USERDAILYDATAORTODO_PULLED_FROM_SERVER @"user_daily_data_or_todo_pulled_from_server"
#define EVENT_USERDAILYDATA_PULLED_FROM_HEALTH_KIT @"user_daily_data_pulled_from_health_kit"

//genius
#define EVENT_GENIUS_THUMB_VIEW_CLICKED @"genius_thumb_view_clicked"
#define EVENT_GENIUS_THUMB_VIEW_CLOSED @"genius_thumb_view_closed"

#define EVENT_UNREAD_NOTIFICATIONS_CLEARED @"unread_notifications_cleared"
#define EVENT_UNREAD_INSIGHTS_CLEARED @"unread_insights_cleared"

#define EVENT_GENIUS_UNREAD_VIEW_HAS_BEEN_SHOWN @"event_genius_unread_view_has_been_shown"

//charts
//#define EVENT_CHART_RANGED_CHANGED @"chart_range_changed"
#define EVENT_CHART_NEEDS_UPDATE_TEMP @"chart_needs_upddate_temp"
#define EVENT_CHART_NEEDS_UPDATE_WEIGHT @"chart_needs_upddate_weight"
#define EVENT_CHART_NEEDS_UPDATE_CALORIE @"chart_needs_upddate_calorie"
#define EVENT_CHART_NEEDS_UPDATE_NUTRITION @"chart_needs_upddate_nutrition"

#define EVENT_GO_DAILYLOG_WEIGHT @"go_dailylog_weight"

//3rd party app connection
#define EVENT_GO_CONNECTING_3RD_PARTY @"go_connecting_3rd_party"
#define EVENT_SHOW_ME_CONNECTION_SECTION @"show_me_connection_section"

// app level events
#define EVENT_APP_DID_LAUNCH @"event_app_did_launch"
#define EVENT_APP_RECEIVE_NOTIFICATION @"app_receive_notification"
#define EVENT_APP_BECOME_ACTIVE @"event_become_active"
#define EVENT_APP_BECOME_INACTIVE @"event_become_inactive"

// Testkit brand picker
#define EVENT_BRAND_PICKER_DID_SHOW @"event_brand_picker_did_show"
#define EVENT_BRAND_PICKER_DID_HIDE @"event_brand_picker_did_hide"

// Dialog
#define EVENT_DIALOG_CLOSE_BUTTON_CLICKED @"dialog_close_button_clicked"
#define EVENT_DIALOG_DISMISSED @"dialog_dismissed"
#define EVENT_MED_UPDATED @"med_updated"
#define EVENT_MED_ADDED @"event_med_added"

// User activity updated
#define EVENT_ACTIVITY_UPDATED @"activity_updated"
#define EVENT_ACTIVITY_GF_DEMO_UPDATED @"activity_gf_demo_updated"

// Forum
#define EVENT_FORUM_NEED_UPDATE_RED_DOT @"event_forum_need_update_red_dot"
#define EVENT_FORUM_ADD_TOPIC_SUCCESS @"event_forum_add_topic_success"
#define EVENT_FORUM_ADD_TOPIC_FAILURE @"event_forum_add_topic_failure"
#define EVENT_FORUM_ADD_REPLY_SUCCESS @"event_forum_add_reply_success"
#define EVENT_FORUM_ADD_REPLY_FAILURE @"event_forum_add_reply_failure"
#define EVENT_FORUM_ADD_SUBREPLY_SUCCESS @"event_forum_add_subreply_success"
#define EVENT_FORUM_CATEGORY_CHANGED @"event_forum_category_changed"

#define EVENT_FORUM_CLICK_GROUPS_BTN @"event_forum_click_groups_btn"
#define EVENT_FORUM_ROOMS_DID_SHOW @"event_forum_rooms_did_show"
#define EVENT_FORUM_BACK_TO_GROUP @"event_forum_back_to_group"
#define EVENT_FORUM_ROOMS_WILL_HIDE @"event_forum_rooms_will_hide"
#define EVENT_FORUM_ROOMS_DID_HIDE @"event_forum_rooms_did_hide"
#define EVENT_FORUM_ROOMS_DID_CHANGE @"event_forum_rooms_did_change"
#define EVENT_FORUM_TUTORIAL_COMPLETE @"event_forum_tutorial_complete"
#define EVENT_FORUM_TUTORIAL_DID_START @"event_forum_tutorial_did_start"
#define EVENT_SHOW_COMMUNITY_POPUP @"event_show_community_popup"
#define EVENT_HIDE_COMMUNITY_POPUP @"event_hide_community_popup"
#define EVENT_FORUM_GOTO_FIRST_ROOM @"event_forum_goto_first_room"

#define EVENT_FORUM_TOPICS_START_LOAD @"event_forum_topics_start_load"
#define EVENT_FORUM_TOPICS_STOP_LOAD @"event_forum_topics_stop_load"
#define EVENT_FORUM_REPLY_REMOVED @"event_forum_reply_removed"

#define EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED @"event_forum_group_subscription_updated"
#define EVENT_FORUM_GROUP_LOCAL_SUBSCRIPTION_UPDATED @"event_forum_group_local_subscription_updated"
#define EVENT_FORUM_GROUP_CREATED @"event_forum_group_created"

#define EVENT_FORUM_SEARCH_CANCEL @"event_forum_search_cancel"

// Forum Poll
#define EVENT_FORUM_POLL_ADD_OPTION @"event_forum_poll_add_option"
#define EVENT_FORUM_POLL_REMOVE_OPTION @"event_forum_poll_remove_option"
#define EVENT_FORUM_POLL_OPTION_VOTE @"event_forum_poll_option_vote"
#define EVENT_DAILY_POLL_LOADED @"event_daily_poll_loaded"
#define EVENT_FORUM_POLL_REFRESHED @"event_forum_poll_refreshed"

// Various app purpose
#define EVENT_SWITCHING_PURPOSE_INFO_MADE_UP @"event_switching_purpose_info_made_up"
#define EVENT_SWITCH_PREGNANT_CANCELLED @"event_switch_pregnant_cancelled"
#define EVENT_SWITCH_PREGNANT_CONFIRMED @"event_switch_pregnant_confirmed"
#define EVENT_SWITCH_FROM_PREGNANT @"event_switch_from_pregnant"

// Fund
#define EVENT_APPLY_OVATION_REVIEW @"apply_ovation_review"
#define EVENT_GET_OVATION_REVIEW_BEFORE @"get_ovation_review_before"
#define EVENT_GET_CARD @"event_get_card"
#define EVENT_CARDNUMBER_CHANGED @"event_card_number_changed"
#define EVENT_JOIN_FUND @"event_join_fund"
#define EVENT_FUND_SYNC_SUMMARY @"event_fund_sync_summary"
#define EVENT_FUND_SYNC_GRANT @"event_fund_sync_grant"
#define EVENT_FUND_SYNC_PAID @"event_fund_sync_paid"
#define EVENT_FUND_USER_PREGNANT  @"event_fund_user_pregnant"
#define EVENT_FUND_ENTERPRISE_APPLY @"event_fund_enterprise_apply"
#define EVENT_FUND_ENTERPRISE_VERIFY @"event_fund_enterprise_verify"
#define EVENT_FUND_ENTERPRISE_APPLY_BY_PHOTO @"event_fund_enterprise_apply_by_photo"
#define EVENT_FUND_QUIT_DEMO_PRESSED @"event_fund_quit_demo_pressed"
#define EVENT_FUND_START_DEMO @"event_fund_start_demo"
#define EVENT_FUND_QUIT_DEMO @"event_fund_quit_demo"
#define EVENT_FUND_GET_QUIT_DEMO_TIME @"event_fund_get_quit_demo_time"
#define EVENT_FUND_SEND_EMAIL_TO_ENTERPRISE @"event_fund_send_email_to_enterprise"
#define EVENT_FUND_SYNC_BALANCE @"event_fund_sync_balance"
#define EVENT_FUND_AGREE_CLAIM_TERM @"event_fund_agree_claim_term"
#define EVENT_FUND_CLAIM_SUCCESS @"event_fund_claim_success"
#define EVENT_FUND_CLAIM_ERROR @"event_fund_claim_error"

// Fulfillment
#define EVENT_FULFILLMENT_PURCHASE_SUCCESSFUL @"fulfillment_purchase_successful"



#define EVENT_GET_ALL_SHARE_LINK @"event_get_all_share_link"
#define EVENT_SHOW_GG_TUTORIAL_POPUP @"event_show_gg_tutorial_popup"


// access address book
#define EVENT_ACCESS_ADDRESS_BOOK_ERROR @"event_access_address_book_error"
#define EVENT_ACCESS_ADDRESS_BOOK_SUCCESS @"event_access_address_book_success"
#define EVENT_EMAIL_GLOW_USER_LOAD_SUCCESS @"event_email_glow_user_load_success"
#define EVENT_EMAIL_GLOW_USER_LOAD_ERROR @"event_email_glow_user_load_error"
#define EVENT_CONTACT_CELL_CLICKED @"event_contact_cell_clicked"

#define EVENT_EMAIL_VIEW_SEND_SUCCESS @"event_email_view_send_success"
#define EVENT_EMAIL_VIEW_SEND_ERROR @"event_email_view_send_error"

#define EVENT_DID_CLICK_COMMUNITY_TAB @"event_did_click_community_tab"

// walgreens
#define EVENT_WALGREENS_CALLBACK_CLOSE @"event_walgreens_callback_close"
#define EVENT_WALGREENS_CALLBACK_REFILL @"event_walgreens_callback_refill"
#define EVENT_WALGREENS_CALLBACK_TRY_AGAIN @"event_walgreens_callback_try_again"

// humanapi
#define EVENT_HUMAN_API_AUTH_FINISHED @"event_human_api_auth_finished"
#define EVENT_HUMAN_API_SUMMARY_DATA_UPDATED @"event_human_api_summary_data_updated"


#endif
