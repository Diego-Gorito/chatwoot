<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import kanban2Module from 'kanban2/store/modules/kanban2';
import Kanban2BoardModal from 'kanban2/components/Kanban2BoardModal.vue';
import { useKanban2BoardModal } from 'kanban2/composables/useKanban2BoardModal';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

if (!store.hasModule('kanban2')) {
  store.registerModule('kanban2', kanban2Module);
}

const boards = computed(() => store.state.kanban2.boards);
const isLoading = computed(() => store.state.kanban2.isLoading);
const preferences = computed(() => store.state.kanban2.preferences);

const favoriteBoardIds = computed(
  () => preferences.value?.favorite_board_ids || []
);

const favoriteBoards = computed(() => {
  return boards.value.filter(f => favoriteBoardIds.value.includes(f.id));
});

const otherBoards = computed(() => {
  return boards.value.filter(f => !favoriteBoardIds.value.includes(f.id));
});

const boardGroups = computed(() => {
  const groups = [];
  const favs = favoriteBoards.value;
  const others = otherBoards.value;

  if (favs.length > 0) {
    groups.push({ title: t('KANBAN.BOARDS.FAVORITES'), items: favs });
    if (others.length > 0) {
      groups.push({ title: t('KANBAN.BOARDS.ALL_BOARDS'), items: others });
    }
  } else if (boards.value.length > 0) {
    groups.push({ title: null, items: boards.value });
  }
  return groups;
});

const fetchBoards = async () => {
  await store.dispatch('kanban2/fetchBoards');
};

const toggleFavorite = async boardId => {
  await store.dispatch('kanban2/toggleFavoriteBoard', boardId);
};

const {
  showBoardModal,
  isSavingBoard,
  openBoardModal,
  closeBoardModal,
  saveBoard,
} = useKanban2BoardModal({
  onSuccess: newBoard => {
    if (newBoard?.id) {
      router.push({
        name: 'kanban2_board_show',
        params: { boardId: newBoard.id },
      });
    }
  },
});

onMounted(() => {
  fetchBoards();
});
</script>

<template>
  <div
    class="kanban2-overview flex flex-col h-full w-full bg-n-background dark:bg-n-slate-1 overflow-hidden"
  >
    <div class="flex items-center justify-between p-6 border-b border-n-weak">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('SIDEBAR.KANBAN2') }}
        </h1>
        <p class="text-sm text-n-slate-11 mt-1">
          A new, premium Kanban experience sharing your existing data.
        </p>
      </div>
      <button
        class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-lg font-medium transition-colors flex items-center gap-2"
        @click="openBoardModal"
      >
        <div class="i-lucide-plus size-4" />
        {{ t('KANBAN.OVERVIEW.ADD_BOARD') }}
      </button>
    </div>

    <div class="flex-1 overflow-y-auto p-8 scrollbar-custom">
      <div v-if="isLoading" class="max-w-7xl mx-auto space-y-12">
        <div v-for="i in 2" :key="i" class="space-y-6">
          <div class="h-8 w-48 bg-n-slate-3 rounded-md animate-pulse" />
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div
              v-for="j in 3"
              :key="j"
              class="h-48 bg-n-slate-2 border border-n-weak rounded-2xl animate-pulse"
            />
          </div>
        </div>
      </div>

      <div v-else-if="!boards.length" class="h-full flex items-center justify-center p-6">
        <div class="text-center">
          <div class="i-lucide-trello size-16 text-n-slate-7 mx-auto mb-6" />
          <h2 class="text-xl font-medium text-n-slate-12">
            {{ t('KANBAN.OVERVIEW.EMPTY_TITLE') }}
          </h2>
          <p class="text-sm text-n-slate-11 max-w-sm mt-3 mx-auto">
            {{ t('KANBAN.OVERVIEW.EMPTY_DESCRIPTION') }}
          </p>
          <button
            class="mt-8 px-6 py-2.5 bg-n-slate-12 text-n-background dark:text-n-slate-1 dark:bg-n-slate-12 rounded-xl font-medium transition-transform active:scale-95 shadow-lg shadow-black/5"
            @click="openBoardModal"
          >
            {{ t('KANBAN.OVERVIEW.EMPTY_ACTION') }}
          </button>
        </div>
      </div>

      <div v-else class="max-w-7xl mx-auto space-y-12">
        <div
          v-for="(group, groupIndex) in boardGroups"
          :key="groupIndex"
          class="space-y-6"
        >
          <h3 v-if="group.title" class="text-lg font-medium text-n-slate-11">
            {{ group.title }}
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <router-link
              v-for="board in group.items"
              :key="board.id"
              :to="{
                name: 'kanban2_board_show',
                params: { boardId: board.id },
              }"
              class="group relative flex flex-col p-6 bg-n-slate-2 dark:bg-n-slate-2/50 border border-n-weak rounded-2xl hover:border-woot-500/50 hover:bg-woot-500/[0.02] transition-all cursor-pointer overflow-hidden backdrop-blur-sm"
            >
              <div class="flex items-start justify-between mb-4">
                <div class="flex-1 min-w-0">
                  <h2
                    class="text-lg font-semibold text-n-slate-12 truncate group-hover:text-woot-600 transition-colors"
                  >
                    {{ board.name }}
                  </h2>
                  <div class="flex items-center gap-2 mt-1">
                    <span
                      class="text-xs font-medium text-n-slate-11 flex items-center gap-1"
                    >
                      <div class="i-lucide-layers size-3" />
                      {{ board.steps_summary?.length || 0 }} steps
                    </span>
                    <span class="text-n-slate-6">•</span>
                    <span
                      class="text-xs font-medium text-n-slate-11 flex items-center gap-1"
                    >
                      <div class="i-lucide-check-circle size-3" />
                      {{ board.total_tasks_count || 0 }} tasks
                    </span>
                  </div>
                </div>
                <button
                  class="p-2 rounded-lg hover:bg-n-slate-3 transition-colors shrink-0"
                  :class="{
                    'text-yellow-500': favoriteBoardIds.includes(board.id),
                    'text-n-slate-8': !favoriteBoardIds.includes(board.id),
                  }"
                  @click.prevent.stop="toggleFavorite(board.id)"
                >
                  <div
                    :class="
                      favoriteBoardIds.includes(board.id)
                        ? 'i-ri-star-fill'
                        : 'i-lucide-star'
                    "
                    class="size-5"
                  />
                </button>
              </div>

              <div
                v-if="board.steps_summary?.length"
                class="mt-auto flex gap-1.5 overflow-hidden"
              >
                <div
                  v-for="step in board.steps_summary.slice(0, 5)"
                  :key="step.id"
                  class="flex-1 h-1.5 rounded-full"
                  :style="{ backgroundColor: step.color || '#cbd5e1' }"
                  v-tooltip="`${step.name}: ${step.tasks_count}`"
                />
                <div
                  v-if="board.steps_summary.length > 5"
                  class="text-[10px] font-bold text-n-slate-8 flex items-center leading-none"
                >
                  +{{ board.steps_summary.length - 5 }}
                </div>
              </div>

              <div
                class="absolute bottom-0 right-0 p-3 opacity-0 group-hover:opacity-100 transition-all translate-y-2 group-hover:translate-y-0"
              >
                <div class="i-lucide-arrow-right size-5 text-woot-500" />
              </div>
            </router-link>
          </div>
        </div>
      </div>
    </div>

    <Kanban2BoardModal
      :show="showBoardModal"
      :is-saving="isSavingBoard"
      @close="closeBoardModal"
      @save="saveBoard"
    />
  </div>
</template>

<style scoped>
.scrollbar-custom::-webkit-scrollbar {
  width: 6px;
}
.scrollbar-custom::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-custom::-webkit-scrollbar-thumb {
  background: rgba(var(--n-slate-4), 0.5);
  border-radius: 10px;
}
.scrollbar-custom::-webkit-scrollbar-thumb:hover {
  background: rgba(var(--n-slate-4), 0.8);
}
</style>
