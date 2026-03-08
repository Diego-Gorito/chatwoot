import { ROLES } from 'dashboard/constants/permissions';

const Kanban2OverviewPage = () => import('./pages/Kanban2OverviewPage.vue');
const Kanban2BoardPage = () => import('./pages/Kanban2BoardPage.vue');

const KANBAN_ROLES = Object.values(ROLES);

export default {
  path: 'kanban2',
  name: 'kanban2',
  meta: {
    permissions: KANBAN_ROLES,
  },
  component: () => import('./Index.vue'),
  children: [
    {
      path: 'overview',
      name: 'kanban2_overview',
      component: Kanban2OverviewPage,
      meta: {
        permissions: KANBAN_ROLES,
      },
    },
    {
      path: 'boards/:boardId?',
      name: 'kanban2_board_show',
      component: Kanban2BoardPage,
      meta: {
        permissions: KANBAN_ROLES,
      },
      // Keep empty children just in case the original had 'create' or 'task/:taskId'
      children: [],
    },
  ],
};
