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
      <button class="px-5 py-2.5 bg-woot-500 hover:bg-woot-600 active:bg-woot-700 text-white rounded-xl font-medium shadow-sm transition-all focus:ring-2 focus:ring-woot-300">
        Create Board
      </button>
    </div>

    <div v-else class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Header Area -->
      <header class="flex pl-8 items-center justify-between pb-6 flex-shrink-0">
        <div>
          <h1 class="text-2xl font-bold tracking-tight text-n-slate-12">
            Kanban 2 <span class="text-woot-500 font-normal">✨</span>
          </h1>
          <p class="text-n-slate-11 text-sm mt-1">
            Organize everything effortlessly in a beautiful pipeline.
          </p>
        </div>
        
        <div class="flex items-center gap-3">
          <button class="flex items-center gap-2 px-4 py-2 bg-white dark:bg-n-slate-3 border border-n-weak hover:border-n-strong rounded-xl text-sm font-medium text-n-slate-12 shadow-sm transition-all">
            <span class="i-lucide-filter size-4"></span>
            Filter
          </button>
          <button class="flex items-center gap-2 px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-sm font-medium shadow-md shadow-woot-500/20 transition-all">
            <span class="i-lucide-plus size-4"></span>
            Add Task
          </button>
        </div>
      </header>

      <!-- Board Area -->
      <div class="flex-1 overflow-x-auto overflow-y-hidden pb-4">
         <Kanban2Board v-if="activeBoard" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import kanban2Module from 'kanban2/store/modules/kanban2';
import Kanban2Board from 'kanban2/components/Kanban2Board.vue';

const store = useStore();
const route = useRoute();

// Ensure our isolated store module is loaded
if (!store.hasModule('kanban2')) {
  store.registerModule('kanban2', kanban2Module);
}

// Vuex State Mappings
const boards = computed(() => store.state.kanban2.boards || []);
const activeBoard = computed(() => store.getters['kanban2/activeBoard']);
const isLoading = computed(() => store.state.kanban2.isLoading);
const selectedBoardId = computed(() => store.state.kanban2.selectedBoardId);

onMounted(async () => {
  await store.dispatch('kanban2/fetchBoards');
  const boardId = route.params.boardId;
  
  if (boards.value.length > 0) {
    // Select the board from URL or default to the first one available
    const boardToSelect = boards.value.find(b => String(b.id) === String(boardId)) || boards.value[0];
    await store.dispatch('kanban2/setActiveBoard', {
      boardId: boardToSelect.id,
    });
  }
});
</script>

<style scoped>
/* Scoped overrides if needed, relying mostly on Tailwind */
</style>
