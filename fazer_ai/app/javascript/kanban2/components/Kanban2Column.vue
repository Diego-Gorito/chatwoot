<template>
  <div class="kanban2-column flex flex-col w-[320px] bg-n-alpha-1 dark:bg-n-slate-2 rounded-2xl border border-n-weak flex-shrink-0 h-full max-h-full">
    <!-- Column Header -->
    <div class="px-4 py-3 flex items-center justify-between border-b border-n-weak sticky top-0 bg-n-alpha-1 dark:bg-n-slate-2 rounded-t-2xl z-10 backdrop-blur-md">
      <div class="flex items-center gap-2 min-w-0">
        <h3 class="font-medium text-sm text-n-slate-12 truncate">
          {{ step.name }}
        </h3>
        <span class="flex items-center justify-center bg-n-alpha-2 dark:bg-n-slate-3 text-n-slate-11 text-xs font-semibold px-2 py-0.5 rounded-full">
          {{ tasks.length }}
        </span>
      </div>
      
      <button class="p-1.5 text-n-slate-10 hover:text-n-slate-12 hover:bg-n-alpha-2 dark:hover:bg-n-slate-4 rounded-lg transition-colors">
        <span class="i-lucide-more-horizontal size-4"></span>
      </button>
    </div>

    <!-- Draggable Area -->
    <div class="flex-1 overflow-y-auto overflow-x-hidden p-2">
      <draggable
        v-model="internalTasks"
        group="kanban-tasks"
        :animation="200"
        item-key="id"
        class="min-h-[100px] h-full flex flex-col gap-2 pb-10"
        ghost-class="opacity-50"
        drag-class="rotate-2 scale-105 shadow-xl transition-transform"
        @change="onDragChange"
      >
        <template #item="{ element }">
          <Kanban2TaskCard :task="element" />
        </template>
        
        <template #footer>
           <button class="mt-2 w-full flex items-center gap-2 p-2 rounded-xl text-n-slate-10 hover:text-woot-500 hover:bg-woot-50 dark:hover:bg-woot-900/20 transition-colors text-sm font-medium group text-left">
             <span class="i-lucide-plus size-4 transition-transform group-hover:scale-110"></span>
             Add Task
           </button>
        </template>
      </draggable>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import Kanban2TaskCard from './Kanban2TaskCard.vue';

const props = defineProps({
  step: {
    type: Object,
    required: true,
  },
  tasks: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();

// Local copy for smooth dragging before backend sync
const internalTasks = ref([...props.tasks]);

watch(() => props.tasks, (newTasks) => {
  internalTasks.value = [...newTasks];
}, { deep: true });

const onDragChange = (evt) => {
  if (evt.added) {
    store.dispatch('kanban2/moveTask', {
      taskId: evt.added.element.id,
      position: evt.added.newIndex + 1, // 1-indexed for backend typically
      stepId: props.step.id,
    });
  } else if (evt.moved) {
    store.dispatch('kanban2/moveTask', {
      taskId: evt.moved.element.id,
      position: evt.moved.newIndex + 1,
      stepId: props.step.id,
    });
  }
};

</script>

<style scoped>
/* Scrollbar styling for a cleaner look */
.kanban2-column ::-webkit-scrollbar {
  width: 6px;
}
.kanban2-column ::-webkit-scrollbar-thumb {
  background-color: var(--color-n-slate-4);
  border-radius: 9999px;
}
</style>
