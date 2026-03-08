<template>
  <div class="group bg-white dark:bg-n-slate-3 p-3.5 rounded-xl border border-n-weak hover:border-woot-300 dark:hover:border-woot-700 hover:shadow-md cursor-grab active:cursor-grabbing transition-all flex flex-col gap-3 relative">
    
    <!-- Badges / Priorities -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-1.5 flex-wrap">
        <span v-if="task.priority" 
              class="px-2 py-0.5 rounded-md text-[11px] font-bold uppercase tracking-wider"
              :class="priorityClasses(task.priority)">
          {{ task.priority }}
        </span>
        <span v-else class="px-2 py-0.5 rounded-md text-[11px] font-medium bg-n-alpha-1 dark:bg-n-slate-4 text-n-slate-11">
          No Priority
        </span>
      </div>
      
      <!-- Quick Actions (Hover) -->
      <div class="opacity-0 group-hover:opacity-100 transition-opacity flex space-x-1 bg-white/80 dark:bg-n-slate-3/80 backdrop-blur-sm rounded-lg shadow-sm p-0.5 absolute top-2 right-2">
         <button class="p-1 text-n-slate-9 hover:text-woot-500 rounded"><span class="i-lucide-edit-2 size-3.5"></span></button>
      </div>
    </div>

    <!-- Title -->
    <div>
      <h4 class="text-sm font-medium text-n-slate-12 leading-snug line-clamp-2">
        {{ task.title }}
      </h4>
      <p v-if="task.description" class="text-xs text-n-slate-10 mt-1 line-clamp-2">
        {{ task.description }}
      </p>
    </div>

    <!-- Footer meta: Assignees & Due Date -->
    <div class="flex items-center justify-between mt-1 pt-3 border-t border-n-weak/50">
      
      <!-- Assignee Avatars (simplified for prototype) -->
      <div class="flex -space-x-2 overflow-hidden mt-1">
        <div v-if="task.assignee" class="flex size-6 rounded-full ring-2 ring-white dark:ring-n-slate-3 bg-gradient-to-tr from-woot-400 to-indigo-400 items-center justify-center text-[10px] text-white font-bold shadow-sm">
          {{ initials(task.assignee.name || 'User') }}
        </div>
        <div v-else class="flex size-6 rounded-full border border-dashed border-n-slate-8 bg-n-alpha-1 dark:bg-n-slate-4 items-center justify-center text-n-slate-10">
          <span class="i-lucide-user size-3"></span>
        </div>
      </div>
      
      <div class="flex items-center gap-1 text-xs text-n-slate-10 font-medium">
        <span v-if="task.due_date" class="flex items-center gap-1 bg-n-alpha-1 dark:bg-n-slate-4 px-2 py-1 rounded-md">
           <span class="i-lucide-calendar size-3"></span>
           {{ formatDate(task.due_date) }}
        </span>
      </div>
    </div>

  </div>
</template>

<script setup>
const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const priorityClasses = (priority) => {
  switch (priority?.toLowerCase()) {
    case 'high':
    case 'urgent':
      return 'bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-400';
    case 'medium':
      return 'bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400';
    case 'low':
      return 'bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400';
    default:
      return 'bg-n-alpha-2 text-n-slate-11';
  }
};

const initials = (name) => {
  return name.substring(0, 2).toUpperCase();
};

const formatDate = (dateStr) => {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};
</script>

<style scoped>
</style>
