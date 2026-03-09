<template>
  <div class="h-full w-full pt-8 flex bg-n-background dark:bg-n-solid-1 text-slate-800">
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="size-8 animate-spin text-woot-500 i-lucide-loader-2" />
    </div>

    <div v-else-if="!boards.length" class="flex-1 flex flex-col items-center justify-center">
      <div class="i-lucide-trello size-12 text-n-slate-9 mb-4" />
      <h2 class="text-xl font-semibold mb-2 text-n-slate-12">No Boards Found</h2>
      <p class="text-n-slate-11 mb-6 text-center max-w-md">
        Create your first board to start managing your conversations and tasks with a premium Kanban experience.
      </p>
      <button
        class="px-5 py-2.5 bg-woot-500 hover:bg-woot-600 active:bg-woot-700 text-white rounded-xl font-medium shadow-sm transition-all focus:ring-2 focus:ring-woot-300"
        @click="openBoardModal"
      >
        Create Board
      </button>
    </div>

    <div v-else class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Header Area -->
      <header class="flex pl-8 pr-4 items-center justify-between pb-6 flex-shrink-0">
        <!-- Left Side: Board Name + Switcher -->
        <div class="flex items-center gap-3">
          <!-- Board Switcher Button -->
          <div class="relative">
            <button
              class="flex items-center gap-2 px-3 py-2 bg-white dark:bg-n-slate-3 border border-n-weak hover:border-n-strong rounded-xl text-sm font-semibold text-n-slate-12 shadow-sm transition-all"
              @click="showBoardSwitcher = !showBoardSwitcher"
            >
              <span class="max-w-[200px] truncate">{{ activeBoardName }}</span>
              <span class="i-lucide-chevron-down size-4 text-n-slate-11" />
            </button>

            <!-- Board Switcher Dropdown -->
            <div
              v-if="showBoardSwitcher"
              v-on-click-outside="() => (showBoardSwitcher = false)"
              class="absolute top-full left-0 mt-2 w-64 bg-white dark:bg-n-slate-2 border border-n-weak rounded-xl shadow-lg z-50 overflow-hidden"
            >
              <div class="p-2 border-b border-n-weak">
                <p class="text-xs font-medium text-n-slate-11 px-2 py-1">
                  BOARDS
                </p>
              </div>
              <div class="max-h-64 overflow-y-auto">
                <button
                  v-for="board in boards"
                  :key="board.id"
                  class="w-full px-3 py-2 text-left text-sm hover:bg-n-slate-3 transition-colors flex items-center justify-between"
                  :class="{
                    'bg-woot-50 dark:bg-woot-900/20 text-woot-600 dark:text-woot-400':
                      board.id === selectedBoardId,
                    'text-n-slate-12': board.id !== selectedBoardId,
                  }"
                  @click="navigateToBoard(board.id)"
                >
                  <span class="truncate">{{ board.name }}</span>
                  <span
                    v-if="board.id === selectedBoardId"
                    class="i-lucide-check size-4 text-woot-500"
                  />
                </button>
              </div>
              <div class="p-2 border-t border-n-weak">
                <button
                  class="w-full px-3 py-2 text-left text-sm text-woot-500 hover:bg-woot-50 dark:hover:bg-woot-900/20 rounded-lg transition-colors flex items-center gap-2"
                  @click="
                    openBoardModal();
                    showBoardSwitcher = false;
                  "
                >
                  <span class="i-lucide-plus size-4" />
                  Create Board
                </button>
              </div>
            </div>
          </div>

          <!-- Task Count Badge -->
          <span
            v-if="activeBoard"
            class="flex items-center justify-center h-6 px-2.5 rounded-full bg-n-slate-3 text-xs font-medium text-n-slate-11"
          >
            {{ filteredTotalTasks }} tasks
          </span>
        </div>

        <!-- Right Side: Filters + Actions -->
        <div class="flex items-center gap-2">
          <!-- Show Completed Button -->
          <button
            v-tooltip="
              showCompleted ? 'Hide completed tasks' : 'Show completed tasks'
            "
            class="flex items-center justify-center size-9 rounded-xl border transition-all"
            :class="{
              'bg-teal-50 dark:bg-teal-900/20 border-teal-200 dark:border-teal-800 text-teal-600':
                showCompleted,
              'bg-white dark:bg-n-slate-3 border-n-weak hover:border-n-strong text-n-slate-11':
                !showCompleted,
            }"
            @click="showCompleted = !showCompleted"
          >
            <span class="i-lucide-check-circle-2 size-4" />
          </button>

          <!-- Show Cancelled Button -->
          <button
            v-tooltip="
              showCancelled ? 'Hide cancelled tasks' : 'Show cancelled tasks'
            "
            class="flex items-center justify-center size-9 rounded-xl border transition-all"
            :class="{
              'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-600':
                showCancelled,
              'bg-white dark:bg-n-slate-3 border-n-weak hover:border-n-strong text-n-slate-11':
                !showCancelled,
            }"
            @click="showCancelled = !showCancelled"
          >
            <span class="i-lucide-x-circle size-4" />
          </button>

          <!-- Divider -->
          <div class="w-px h-6 bg-n-weak mx-1" />

          <!-- Agent Filter -->
          <select
            v-model="selectedAgentId"
            class="px-3 py-2 bg-white dark:bg-n-slate-3 border border-n-weak hover:border-n-strong rounded-xl text-sm text-n-slate-12 shadow-sm transition-all appearance-none cursor-pointer pr-8"
            style="
              background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27currentColor%27 stroke-width=%272%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3e%3cpolyline points=%276 9 12 15 18 9%27%3e%3c/polyline%3e%3c/svg%3e');
              background-repeat: no-repeat;
              background-position: right 0.5rem center;
              background-size: 1em;
            "
          >
            <option value="all">All Agents</option>
            <option v-for="agent in agents" :key="agent.id" :value="agent.id">
              {{ agent.name }}
            </option>
          </select>

          <!-- Inbox Filter -->
          <select
            v-model="selectedInboxId"
            class="px-3 py-2 bg-white dark:bg-n-slate-3 border border-n-weak hover:border-n-strong rounded-xl text-sm text-n-slate-12 shadow-sm transition-all appearance-none cursor-pointer pr-8"
            style="
              background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27currentColor%27 stroke-width=%272%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3e%3cpolyline points=%276 9 12 15 18 9%27%3e%3c/polyline%3e%3c/svg%3e');
              background-repeat: no-repeat;
              background-position: right 0.5rem center;
              background-size: 1em;
            "
          >
            <option value="all">All Inboxes</option>
            <option
              v-for="inbox in inboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>

          <!-- Sort Menu -->
          <div class="relative">
            <button
              v-tooltip="'Sort tasks'"
              class="flex items-center justify-center size-9 rounded-xl border bg-white dark:bg-n-slate-3 border-n-weak hover:border-n-strong text-n-slate-11 transition-all"
              @click="showSortMenu = !showSortMenu"
            >
              <span class="i-lucide-arrow-up-down size-4" />
            </button>

            <div
              v-if="showSortMenu"
              v-on-click-outside="() => (showSortMenu = false)"
              class="absolute top-full right-0 mt-2 w-48 bg-white dark:bg-n-slate-2 border border-n-weak rounded-xl shadow-lg z-50 overflow-hidden"
            >
              <button
                v-for="option in sortOptions"
                :key="option.value"
                class="w-full px-3 py-2 text-left text-sm hover:bg-n-slate-3 transition-colors flex items-center justify-between"
                :class="{
                  'bg-woot-50 dark:bg-woot-900/20 text-woot-600':
                    activeSort === option.value,
                  'text-n-slate-12': activeSort !== option.value,
                }"
                @click="onSortChange(option.value)"
              >
                <span>{{ option.label }}</span>
                <span
                  v-if="activeSort === option.value"
                  class="i-lucide-check size-4"
                />
              </button>
            </div>
          </div>

          <!-- Settings Button (Admin Only) -->
          <router-link
            v-if="selectedBoardId && isAdmin"
            :to="{
              name: 'kanban_board_settings',
              params: {
                accountId: route.params.accountId,
                boardId: selectedBoardId,
              },
            }"
          >
            <button
              v-tooltip="'Board settings'"
              class="flex items-center justify-center size-9 rounded-xl border bg-white dark:bg-n-slate-3 border-n-weak hover:border-n-strong text-n-slate-11 transition-all"
            >
              <span class="i-lucide-settings size-4" />
            </button>
          </router-link>

          <!-- Add Task Button -->
          <button
            class="flex items-center gap-2 px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-sm font-medium shadow-md shadow-woot-500/20 transition-all"
            @click="openCreateModal"
          >
            <span class="i-lucide-plus size-4" />
            Add Task
          </button>
        </div>
      </header>

      <!-- Board Area -->
      <div class="flex-1 overflow-x-auto overflow-y-hidden pb-4">
        <Kanban2Board
          v-if="activeBoard"
          :steps="filteredSteps"
          :show-completed="showCompleted"
          :show-cancelled="showCancelled"
          @add-task="openCreateModal"
        />
      </div>
    </div>

    <!-- Board Modal -->
    <Kanban2BoardModal
      v-if="showBoardModal"
      @close="showBoardModal = false"
      @save="handleBoardSave"
    />

    <!-- Task Modal -->
    <Kanban2TaskModal
      v-if="showTaskModal"
      :task="selectedTask"
      :board-id="selectedBoardId"
      :step-id="selectedStepId"
      @close="closeTaskModal"
      @save="handleTaskSave"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import kanban2Module from 'kanban2/store/modules/kanban2';
import Kanban2Board from 'kanban2/components/Kanban2Board.vue';
import Kanban2BoardModal from 'kanban2/components/Kanban2BoardModal.vue';
import Kanban2TaskModal from 'kanban2/components/Kanban2TaskModal.vue';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { isAdmin } = useAdmin();

// Ensure our isolated store module is loaded
if (!store.hasModule('kanban2')) {
  store.registerModule('kanban2', kanban2Module);
}

// Vuex State Mappings
const boards = computed(() => store.state.kanban2.boards || []);
const activeBoard = computed(() => store.getters['kanban2/activeBoard']);
const isLoading = computed(() => store.state.kanban2.isLoading);
const selectedBoardId = computed(() => store.state.kanban2.selectedBoardId);
const steps = computed(() => store.getters['kanban2/orderedSteps'] || []);
const agents = computed(() => store.state.agents?.records || []);
const inboxes = computed(() => store.state.inboxes?.records || []);
const preferences = computed(() => store.state.kanban2.preferences);

// UI State
const showBoardSwitcher = ref(false);
const showSortMenu = ref(false);
const showBoardModal = ref(false);
const showTaskModal = ref(false);
const selectedTask = ref(null);
const selectedStepId = ref(null);

// Filters
const showCompleted = ref(false);
const showCancelled = ref(false);
const selectedAgentId = ref('all');
const selectedInboxId = ref('all');
const activeSort = ref('position');
const activeOrdering = ref('asc');

// Computed
const activeBoardName = computed(
  () => activeBoard.value?.name || 'Select Board'
);

const filteredSteps = computed(() => {
  return steps.value.filter(step => {
    if (step.inferred_task_status === 'completed' && !showCompleted.value) {
      return false;
    }
    if (step.inferred_task_status === 'cancelled' && !showCancelled.value) {
      return false;
    }
    return true;
  });
});

const filteredTotalTasks = computed(() => {
  // Calculate total from all steps
  let total = 0;
  steps.value.forEach(step => {
    if (
      (step.inferred_task_status === 'completed' && !showCompleted.value) ||
      (step.inferred_task_status === 'cancelled' && !showCancelled.value)
    ) {
      return;
    }
    total += step.tasks_count || 0;
  });
  return total;
});

const sortOptions = [
  { label: 'Position', value: 'position' },
  { label: 'Last Updated', value: 'updated_at' },
  { label: 'Created Date', value: 'created_at' },
  { label: 'Due Date', value: 'due_date' },
  { label: 'Priority', value: 'priority' },
];

// Methods
const navigateToBoard = boardId => {
  if (!boardId || !route.params.accountId) return;

  router.push({
    name: 'kanban2_board_show',
    params: {
      accountId: route.params.accountId,
      boardId,
    },
  });

  showBoardSwitcher.value = false;
};

const openBoardModal = () => {
  showBoardModal.value = true;
};

const handleBoardSave = async boardData => {
  try {
    const newBoard = await store.dispatch('kanban2/createBoard', boardData);
    showBoardModal.value = false;
    useAlert(t('KANBAN.BOARD_MODAL.CREATE_SUCCESS'));

    // Navigate to the new board
    if (newBoard?.id) {
      navigateToBoard(newBoard.id);
    }
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) || t('KANBAN.BOARD_MODAL.CREATE_ERROR')
    );
  }
};

const openCreateModal = (stepId = null) => {
  selectedTask.value = null;
  selectedStepId.value = stepId || steps.value[0]?.id;
  showTaskModal.value = true;
};

const closeTaskModal = () => {
  showTaskModal.value = false;
  selectedTask.value = null;
  selectedStepId.value = null;
};

const handleTaskSave = async taskData => {
  try {
    if (selectedTask.value?.id) {
      // Update existing task
      await store.dispatch('kanban2/updateTask', {
        id: selectedTask.value.id,
        task: taskData,
      });
      useAlert(t('KANBAN.TASK_MODAL.UPDATE_SUCCESS'));
    } else {
      // Create new task
      await store.dispatch('kanban2/createTask', taskData);
      useAlert(t('KANBAN.TASK_MODAL.CREATE_SUCCESS'));
    }
    closeTaskModal();
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) || t('KANBAN.TASK_MODAL.SAVE_ERROR')
    );
  }
};

const onSortChange = async sortValue => {
  activeSort.value = sortValue;
  showSortMenu.value = false;

  if (!selectedBoardId.value) return;

  // Update sorting in store
  await store.dispatch('kanban2/updateTaskSorting', {
    boardId: selectedBoardId.value,
    sort: sortValue,
    order: 'asc',
  });

  // Reset and re-fetch tasks with new sorting
  await store.dispatch('kanban2/resetStepTasks');
  await fetchVisibleStepTasks();
};

const fetchVisibleStepTasks = async () => {
  const visibleSteps = filteredSteps.value;

  await Promise.all(
    visibleSteps.map(step =>
      store.dispatch('kanban2/fetchTasksForStep', {
        stepId: step.id,
        page: 1,
        perPage: 10,
      })
    )
  );
};

const fetchStepsWithFilters = async () => {
  await store.dispatch('kanban2/fetchSteps', {
    boardId: selectedBoardId.value,
    agentId: selectedAgentId.value,
    inboxId: selectedInboxId.value,
  });
};

// Lifecycle
onMounted(async () => {
  // Fetch agents and inboxes
  await Promise.all([
    store.dispatch('agents/get'),
    store.dispatch('inboxes/get'),
  ]);

  // Fetch boards
  await store.dispatch('kanban2/fetchBoards');
  const boardId = route.params.boardId;

  if (boards.value.length > 0) {
    // Select the board from URL or default to the first one available
    const boardToSelect =
      boards.value.find(b => String(b.id) === String(boardId)) ||
      boards.value[0];

    // Load saved filters from preferences
    const boardFilters = preferences.value.board_filters || {};
    const savedFilters = boardFilters[boardToSelect.id] || {};
    selectedAgentId.value = savedFilters.agent_id || 'all';
    selectedInboxId.value = savedFilters.inbox_id || 'all';
    showCompleted.value = savedFilters.show_completed || false;
    showCancelled.value = savedFilters.show_cancelled || false;

    // Load saved sort
    const taskSorting = preferences.value.task_sorting || {};
    const savedSort = taskSorting[boardToSelect.id] || {};
    activeSort.value = savedSort.sort || 'position';
    activeOrdering.value = savedSort.order || 'asc';

    await store.dispatch('kanban2/setActiveBoard', {
      boardId: boardToSelect.id,
      agentId: selectedAgentId.value,
      inboxId: selectedInboxId.value,
    });

    // Fetch tasks for visible steps
    await fetchVisibleStepTasks();
  }
});

// Watch for route changes
watch(
  () => route.params.boardId,
  async newBoardId => {
    if (newBoardId && newBoardId !== String(selectedBoardId.value)) {
      await store.dispatch('kanban2/setActiveBoard', {
        boardId: Number(newBoardId),
        agentId: selectedAgentId.value,
        inboxId: selectedInboxId.value,
      });
      await fetchVisibleStepTasks();
    }
  }
);

// Watch for visibility changes (completed/cancelled toggles)
watch([showCompleted, showCancelled], async () => {
  if (!selectedBoardId.value) return;

  // Fetch tasks for newly visible steps
  await fetchVisibleStepTasks();
});

// Watch filters and apply them
watch(
  [selectedAgentId, selectedInboxId],
  async ([newAgentId, newInboxId], [oldAgentId, oldInboxId]) => {
    if (!selectedBoardId.value) return;

    // Update filters in store
    await store.dispatch('kanban2/updateBoardFilters', {
      boardId: selectedBoardId.value,
      agentId: newAgentId,
      inboxId: newInboxId,
      showCompleted: showCompleted.value,
      showCancelled: showCancelled.value,
    });

    // Re-fetch if agent/inbox changed
    if (newAgentId !== oldAgentId || newInboxId !== oldInboxId) {
      await store.dispatch('kanban2/resetStepTasks');
      await fetchStepsWithFilters();
      await fetchVisibleStepTasks();
    }
  }
);
</script>

<style scoped>
/* Scoped overrides if needed, relying mostly on Tailwind */
</style>
