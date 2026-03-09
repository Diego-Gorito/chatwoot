<template>
  <div class="flex h-full gap-6 pl-8 pr-12 pb-4 min-w-max items-start">
    <Kanban2Column
      v-for="step in visibleSteps"
      :key="step.id"
      :step="step"
      :tasks="stepTasksMap[step.id] || []"
      @add-task="handleAddTask"
      @edit-task="handleEditTask"
    />

    <!-- Add Column Placeholder -->
    <div class="w-[320px] flex-shrink-0 group cursor-pointer">
       <button
         class="w-full h-14 flex items-center justify-center gap-2 rounded-xl border border-dashed border-n-slate-6 dark:border-n-slate-4 bg-transparent hover:bg-n-alpha-1 hover:border-n-slate-8 text-n-slate-11 hover:text-n-slate-12 transition-all"
         @click="handleAddColumn"
       >
         <span class="i-lucide-plus size-4"></span>
         <span class="font-medium text-sm">Add another column</span>
       </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import Kanban2Column from './Kanban2Column.vue';

const props = defineProps({
  steps: {
    type: Array,
    default: () => [],
  },
  showCompleted: {
    type: Boolean,
    default: false,
  },
  showCancelled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['add-task', 'edit-task', 'add-column']);

const store = useStore();

const stepTasksMap = computed(() => store.getters['kanban2/stepTasksMap'] || {});

// Use props.steps instead of fetching from store directly
const visibleSteps = computed(() => props.steps || []);

const handleAddTask = (stepId) => {
  emit('add-task', stepId);
};

const handleEditTask = (task) => {
  emit('edit-task', task);
};

const handleAddColumn = () => {
  emit('add-column');
};

</script>

<style scoped>
</style>
