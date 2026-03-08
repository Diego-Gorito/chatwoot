<script setup>
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

</script>

<template>
  <div class="kanban2-overview flex flex-col h-full w-full bg-n-background dark:bg-n-slate-1">
    <div class="flex items-center justify-between p-6 border-b border-n-weak">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          Kanban 2
        </h1>
        <p class="text-sm text-n-slate-11 mt-1">
          A new, premium Kanban experience.
        </p>
      </div>
    </div>
    <div class="flex-1 flex items-center justify-center p-6">
      <div class="text-center">
        <div class="i-lucide-trello size-12 text-n-slate-9 mx-auto mb-4" />
        <h2 class="text-lg font-medium text-n-slate-12">No Boards Yet</h2>
        <p class="text-sm text-n-slate-11 max-w-sm mt-2">
          Get started by creating your first highly visual Kanban board.
        </p>
        <button
          class="mt-6 px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-lg font-medium transition-colors"
          @click="openBoardModal"
        >
          Create Board
        </button>
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
</style>
