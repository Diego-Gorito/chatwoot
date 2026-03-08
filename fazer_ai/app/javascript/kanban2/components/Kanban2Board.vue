<template>
  <div class="flex h-full gap-6 pl-8 pr-12 pb-4 min-w-max items-start">
    <Kanban2Column
      v-for="step in steps"
      :key="step.id"
      :step="step"
      :tasks="stepTasksMap[step.id] || []"
    />
    
    <!-- Add Column Placeholder -->
    <div class="w-[320px] flex-shrink-0 group cursor-pointer">
       <button class="w-full h-14 flex items-center justify-center gap-2 rounded-xl border border-dashed border-n-slate-6 dark:border-n-slate-4 bg-transparent hover:bg-n-alpha-1 hover:border-n-slate-8 text-n-slate-11 hover:text-n-slate-12 transition-all">
         <span class="i-lucide-plus size-4"></span>
         <span class="font-medium text-sm">Add another column</span>
       </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import Kanban2Column from './Kanban2Column.vue';

const store = useStore();

const steps = computed(() => store.getters['kanban2/orderedSteps'] || []);
const stepTasksMap = computed(() => store.getters['kanban2/stepTasksMap'] || {});
const activeBoard = computed(() => store.getters['kanban2/activeBoard']);

const fetchBoardData = async () => {
  if (!activeBoard.value) return;
  
  await store.dispatch('kanban2/fetchSteps', {
    boardId: activeBoard.value.id,
  });

  // For each step, fetch the initial tasks
  steps.value.forEach(step => {
    store.dispatch('kanban2/fetchTasksForStep', { stepId: step.id });
  });
};

watch(
  () => activeBoard.value?.id,
  (newId, oldId) => {
    if (newId && newId !== oldId) {
      store.dispatch('kanban2/resetStepTasks');
      fetchBoardData();
    }
  },
  { immediate: true }
);

</script>

<style scoped>
</style>
