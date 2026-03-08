import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Kanban2OverviewPage from 'kanban2/pages/Kanban2OverviewPage.vue';
import Kanban2BoardPage from 'kanban2/pages/Kanban2BoardPage.vue';

export default {
  path: frontendURL('accounts/:accountId/kanban2'),
  component: {
    render() {
      return this.$slots.default ? this.$slots.default() : null;
    },
  },
  children: [
    {
      path: 'overview',
      component: Kanban2OverviewPage,
      name: 'kanban2_overview',
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
    {
      path: ':boardId?',
      component: Kanban2BoardPage,
      name: 'kanban2_board_show',
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
  ],
};
