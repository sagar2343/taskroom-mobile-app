// ── Auth ──────────────────────────────────────────────────────────────
const APIRouteRegisterNewUser = '/api/auth/register';
const APIRouteLogin           = '/api/auth/login';

// ── Profile ───────────────────────────────────────────────────────────
const APIRouteProfile        = '/api/user/profile';
const APIRouteChangePassword = '/api/user/change-password';

// ── Room ──────────────────────────────────────────────────────────────
const APIRouteRoom            = '/api/rooms';
const APIRouteGetMyRooms      = '/api/rooms/my-rooms';
const APIRouteJoinRoom        = '/api/rooms/join';
const APIRouteRoomMember      = '/api/rooms/member';
const APIRouteArchiveRoom     = '/api/rooms/archive';
const APIRouteRemoveMember    = '/api/rooms/member/remove';
const APIRouteAddMemberToRoom = '/api/rooms/member/add';

// ── Organization ──────────────────────────────────────────────────────
const APIRouteCheckOrgAvailability = '/api/organization/check';
const APIRouteGetAllOrgMembers     = '/api/organization/members';

// ── Tasks ─────────────────────────────────────────────────────────────
const APIRouteTasks      = '/api/tasks';
const APIRouteGetMyTasks = '/api/tasks/my/tasks';

const APIRouteTaskDetail        = '/api/tasks/detail';
const APIRouteTaskEdit          = '/api/tasks/edit';
const APIRouteTaskCancel        = '/api/tasks/cancel';

const APIRouteTaskStepsAdd    = '/api/tasks/steps/add';
const APIRouteTaskStepsEdit   = '/api/tasks/steps/edit';
const APIRouteTaskStepsRemove = '/api/tasks/steps/remove';

const APIRouteTaskStart        = '/api/tasks/start';
const APIRouteTaskStepsStart   = '/api/tasks/steps/start';
const APIRouteTaskStepsReached = '/api/tasks/steps/reached';
const APIRouteTaskStepsComplete= '/api/tasks/steps/complete';

const APIRouteTaskLocationPing  = '/api/tasks/location/ping';
const APIRouteTaskDashboard     = '/api/tasks/dashboard';
const APIRouteTaskLiveLocation  = '/api/tasks/live-location';
const APIRouteTaskLocationTrace = '/api/tasks/location-trace';

// ── Attendance ────────────────────────────────────────────────────────
const APIRouteAttendanceGoOnline   = '/api/attendance/go-online';
const APIRouteAttendanceGoOffline  = '/api/attendance/go-offline';
const APIRouteAttendanceToday      = '/api/attendance/today';
const APIRouteAttendanceHistory    = '/api/attendance/history';
const APIRouteAttendanceOrgToday   = '/api/attendance/org-today';
const APIRouteAttendaceOfEmployee  = '/api/attendance/employee/';

const APIRouteAttendancePunchIn  = '/api/tasks/attendance/punch-in';
const APIRouteAttendancePunchOut = '/api/tasks/attendance/punch-out';
const APIRouteTaskActiveStatus   = '/api/tasks/active-status';

// ── FCM / Upload ──────────────────────────────────────────────────────
const APIRouteFcmUrl               = '/api/fcm/fcm-token';
const APIRouteUploadProfilePicture = '/api/upload/profile-picture';
const APIRouteUploadStepPhoto      = '/api/upload/step-photo';
const APIRouteUploadRoomImage      = '/api/upload/room-image';

// ── NEW: Billing ──────────────────────────────────────────────────────
/// Public — returns plan catalogue with pricing
const APIRouteBillingPlans        = '/api/billing/plans';
/// Manager — current plan, trial days left, limits
const APIRouteBillingStatus       = '/api/billing/status';
/// Manager — create Razorpay order before checkout
const APIRouteBillingCreateOrder  = '/api/billing/create-order';
/// Manager — verify Razorpay signature after checkout
const APIRouteBillingVerifyPayment = '/api/billing/verify-payment';
/// Manager — payment history
const APIRouteBillingHistory      = '/api/billing/history';

// ── NEW: Export (Pro+ only) ───────────────────────────────────────────
/// Query params: from=, to=, employeeId= (all optional)
const APIRouteExportAttendancePdf   = '/api/export/attendance/pdf';
const APIRouteExportAttendanceExcel = '/api/export/attendance/excel';
const APIRouteExportTasksPdf        = '/api/export/tasks/pdf';
const APIRouteExportTasksExcel      = '/api/export/tasks/excel';
/// Org-wide productivity summary PDF
const APIRouteExportTeamSummaryPdf  = '/api/export/team-summary/pdf';

// ── NEW: Analytics (Pro+ for productivity scores) ────────────────────
/// Today's org snapshot: online count, tasks, overdue
const APIRouteAnalyticsOverview     = '/api/analytics/overview';
/// Weekly productivity scores per employee (Pro+)
const APIRouteAnalyticsProductivity = '/api/analytics/productivity';
/// 30-day single employee detail card
const APIRouteAnalyticsEmployee     = '/api/analytics/employee/'; // append :id
/// Daily trend data — ?days=7|14|30
const APIRouteAnalyticsTrends       = '/api/analytics/trends';
