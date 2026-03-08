import { ROLES } from 'dashboard/constants/permissions';

const KanbanOverviewPage = () => import('./pages/KanbanOverviewPage.vue');
const KanbanBoardPage = () => import('./pages/KanbanBoardPage.vue');
const KanbanBoardSettingsPage = () => import('./pages/KanbanBoardSettingsPage.vue');

export default {
  path: 'kanban',
  name: 'kanban',
  meta: {
    permissions: [ROLES.AGENT, ROLES.ADMINISTRATOR],
  },
  component: () => import('./Index.vue'),
  children: [
    {
      path: 'overview',
      name: 'kanban_overview',
      component: KanbanOverviewPage,
      meta: {
        permissions: [ROLES.AGENT, ROLES.ADMINISTRATOR],
      },
    },
    {
      path: 'boards/:boardId',
      name: 'kanban_board_show',
      component: KanbanBoardPage,
      meta: {
        permissions: [ROLES.AGENT, ROLES.ADMINISTRATOR],
      },
    },
    {
      path: 'boards/:boardId/settings',
      name: 'kanban_board_settings',
      component: KanbanBoardSettingsPage,
      meta: {
        permissions: [ROLES.ADMINISTRATOR],
      },
    },
  ],
};