import { ROLES } from 'dashboard/constants/permissions';

const KanbanOverviewPage = () => import('./pages/KanbanOverviewPage.vue');
const KanbanBoardPage = () => import('./pages/KanbanBoardPage.vue');
const KanbanBoardSettingsPage = () => import('./pages/KanbanBoardSettingsPage.vue');

export default {
  path: 'kanban',
  name: 'kanban',
  meta: {
    permissions: ROLES,
  },
  component: () => import('./Index.vue'),
  children: [
    {
      path: 'overview',
      name: 'kanban_list',
      component: KanbanOverviewPage,
      meta: {
        permissions: ROLES,
      },
    },
    {
      path: 'boards/:boardId',
      name: 'kanban_board_show',
      component: KanbanBoardPage,
      meta: {
        permissions: ROLES,
      },
      children: [
        {
          path: 'create',
          name: 'kanban_task_create',
          component: KanbanBoardPage,
          meta: {
            permissions: ROLES,
          },
        },
        {
          path: 'task/:taskId',
          name: 'kanban_task_show',
          component: KanbanBoardPage,
          meta: {
            permissions: ROLES,
          },
        },
      ],
    },
    {
      path: 'boards/:boardId/settings',
      name: 'kanban_board_settings',
      component: KanbanBoardSettingsPage,
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};