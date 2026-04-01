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
const APIRouteTasks      = '/api/tasks';           // GET  (manager list)
const APIRouteGetMyTasks = '/api/tasks/my/tasks';  // GET  (employee list)

// taskId / stepId are always sent in the request body, never in the URL

// Manager
const APIRouteTaskDetail        = '/api/tasks/detail';          // POST  { taskId }
const APIRouteTaskEdit          = '/api/tasks/edit';            // PUT   { taskId, ...fields }
const APIRouteTaskCancel        = '/api/tasks/cancel';          // PATCH { taskId, reason? }
const APIRouteTaskLiveLocation  = '/api/tasks/live-location';   // POST  { taskId }
const APIRouteTaskLocationTrace = '/api/tasks/location-trace';  // POST  { taskId, stepId? }

// Steps (manager)
const APIRouteTaskStepsAdd    = '/api/tasks/steps/add';     // POST   { taskId, ...step }
const APIRouteTaskStepsEdit   = '/api/tasks/steps/edit';    // PUT    { taskId, stepId, ...fields }
const APIRouteTaskStepsRemove = '/api/tasks/steps/remove';  // DELETE { taskId, stepId }

// Employee actions
const APIRouteTaskStart        = '/api/tasks/start';           // POST { taskId, coordinates? }
const APIRouteTaskStepsStart   = '/api/tasks/steps/start';     // POST { taskId, stepId }
const APIRouteTaskStepsReached = '/api/tasks/steps/reached';   // POST { taskId, stepId, coordinates }
const APIRouteTaskStepsComplete= '/api/tasks/steps/complete';  // POST { taskId, stepId, ...fields }

// Location
const APIRouteTaskLocationPing = '/api/tasks/location/ping';   // POST { taskId, stepId, coordinates, ... }

// ── Attendance ────────────────────────────────────────────────────────
const APIRouteAttendancePunchIn  = '/api/tasks/attendance/punch-in';
const APIRouteAttendancePunchOut = '/api/tasks/attendance/punch-out';
const APIRouteAttendanceToday    = '/api/tasks/attendance/today';
const APIRouteAttendanceHistory  = '/api/tasks/attendance/history';
