<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
    @click.self="handleClose"
  >
    <div
      class="w-full max-w-2xl max-h-[90vh] bg-white dark:bg-n-slate-2 rounded-2xl shadow-2xl overflow-hidden flex flex-col"
      @click.stop
    >
      <!-- Header -->
      <div class="px-6 py-4 border-b border-n-weak flex-shrink-0">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold text-n-slate-12">
            {{ isEditing ? 'Edit Task' : 'Create New Task' }}
          </h2>
          <button
            class="size-8 flex items-center justify-center rounded-lg hover:bg-n-slate-3 transition-colors text-n-slate-11"
            @click="handleClose"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>
      </div>

      <!-- Body -->
      <div class="px-6 py-6 space-y-4 overflow-y-auto flex-1">
        <!-- Task Title -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Title <span class="text-red-500">*</span>
          </label>
          <input
            v-model="taskTitle"
            type="text"
            placeholder="e.g., Follow up with customer, Fix critical bug"
            class="w-full px-4 py-2.5 bg-white dark:bg-n-slate-3 border border-n-weak focus:border-woot-500 focus:ring-2 focus:ring-woot-500/20 rounded-xl text-sm text-n-slate-12 placeholder-n-slate-9 transition-all outline-none"
            :class="{ 'border-red-500': showError && !taskTitle }"
            @keyup.enter="handleSave"
          />
          <p
            v-if="showError && !taskTitle"
            class="mt-1.5 text-xs text-red-500"
          >
            Task title is required
          </p>
        </div>

        <!-- Task Description -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Description (Optional)
          </label>
          <textarea
            v-model="taskDescription"
            rows="4"
            placeholder="Add more details about this task..."
            class="w-full px-4 py-2.5 bg-white dark:bg-n-slate-3 border border-n-weak focus:border-woot-500 focus:ring-2 focus:ring-woot-500/20 rounded-xl text-sm text-n-slate-12 placeholder-n-slate-9 transition-all outline-none resize-none"
          />
        </div>

        <!-- Step Selection -->
        <div v-if="steps.length > 0">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Step
          </label>
          <select
            v-model="selectedStepId"
            class="w-full px-4 py-2.5 bg-white dark:bg-n-slate-3 border border-n-weak focus:border-woot-500 focus:ring-2 focus:ring-woot-500/20 rounded-xl text-sm text-n-slate-12 transition-all outline-none appearance-none cursor-pointer"
            style="
              background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27currentColor%27 stroke-width=%272%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3e%3cpolyline points=%276 9 12 15 18 9%27%3e%3c/polyline%3e%3c/svg%3e');
              background-repeat: no-repeat;
              background-position: right 1rem center;
              background-size: 1em;
              padding-right: 3rem;
            "
          >
            <option
              v-for="step in steps"
              :key="step.id"
              :value="step.id"
            >
              {{ step.name }}
            </option>
          </select>
        </div>

        <!-- Priority -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Priority
          </label>
          <div class="grid grid-cols-4 gap-2">
            <button
              v-for="option in priorityOptions"
              :key="option.value"
              class="px-3 py-2 border-2 rounded-xl text-sm font-medium transition-all"
              :class="{
                'border-woot-500 bg-woot-50 dark:bg-woot-900/20 text-woot-600':
                  taskPriority === option.value,
                'border-n-weak hover:border-n-strong text-n-slate-11 bg-white dark:bg-n-slate-3':
                  taskPriority !== option.value,
              }"
              @click="taskPriority = option.value"
            >
              <span :class="option.icon" class="size-4 mr-1" />
              {{ option.label }}
            </button>
          </div>
        </div>

        <!-- Due Date -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Due Date (Optional)
          </label>
          <input
            v-model="taskDueDate"
            type="date"
            class="w-full px-4 py-2.5 bg-white dark:bg-n-slate-3 border border-n-weak focus:border-woot-500 focus:ring-2 focus:ring-woot-500/20 rounded-xl text-sm text-n-slate-12 transition-all outline-none"
          />
        </div>
      </div>

      <!-- Footer -->
      <div class="px-6 py-4 border-t border-n-weak bg-n-slate-1 dark:bg-n-slate-1/50 flex-shrink-0">
        <div class="flex items-center justify-between">
          <!-- Delete button (only when editing) -->
          <button
            v-if="isEditing"
            class="px-4 py-2 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-xl transition-all"
            @click="handleDelete"
          >
            <span class="i-lucide-trash-2 size-4 mr-1.5" />
            Delete Task
          </button>
          <div v-else />

          <!-- Actions -->
          <div class="flex items-center gap-3">
            <button
              class="px-4 py-2 text-sm font-medium text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-xl transition-all"
              @click="handleClose"
            >
              Cancel
            </button>
            <button
              class="px-5 py-2 bg-woot-500 hover:bg-woot-600 active:bg-woot-700 text-white text-sm font-medium rounded-xl shadow-md shadow-woot-500/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              :disabled="isSaving || !taskTitle"
              @click="handleSave"
            >
              <span v-if="isSaving" class="flex items-center gap-2">
                <span class="i-lucide-loader-2 size-4 animate-spin" />
                {{ isEditing ? 'Updating...' : 'Creating...' }}
              </span>
              <span v-else>
                {{ isEditing ? 'Update Task' : 'Create Task' }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
  task: {
    type: Object,
    default: null,
  },
  boardId: {
    type: Number,
    default: null,
  },
  stepId: {
    type: [Number, String],
    default: null,
  },
  steps: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'save', 'delete']);

// Form state
const taskTitle = ref('');
const taskDescription = ref('');
const taskPriority = ref('medium');
const taskDueDate = ref('');
const selectedStepId = ref(null);
const isSaving = ref(false);
const showError = ref(false);

// Computed
const isEditing = computed(() => !!props.task?.id);

// Priority options
const priorityOptions = [
  {
    value: 'urgent',
    label: 'Urgent',
    icon: 'i-lucide-alert-circle',
  },
  {
    value: 'high',
    label: 'High',
    icon: 'i-lucide-arrow-up',
  },
  {
    value: 'medium',
    label: 'Medium',
    icon: 'i-lucide-minus',
  },
  {
    value: 'low',
    label: 'Low',
    icon: 'i-lucide-arrow-down',
  },
];

// Methods
const handleClose = () => {
  if (!isSaving.value) {
    emit('close');
  }
};

const handleSave = async () => {
  showError.value = true;

  if (!taskTitle.value) {
    return;
  }

  isSaving.value = true;

  try {
    const payload = {
      title: taskTitle.value,
      description: taskDescription.value,
      priority: taskPriority.value,
      due_date: taskDueDate.value || null,
    };

    if (!isEditing.value) {
      // New task
      payload.board_id = props.boardId;
      payload.board_step_id = selectedStepId.value;
    }

    emit('save', payload);
  } finally {
    isSaving.value = false;
  }
};

const handleDelete = () => {
  if (confirm('Are you sure you want to delete this task?')) {
    emit('delete', props.task.id);
  }
};

// Watch for task changes (editing mode)
watch(
  () => props.task,
  newTask => {
    if (newTask) {
      taskTitle.value = newTask.title || '';
      taskDescription.value = newTask.description || '';
      taskPriority.value = newTask.priority || 'medium';
      taskDueDate.value = newTask.due_date || '';
      selectedStepId.value = newTask.board_step_id;
    } else {
      taskTitle.value = '';
      taskDescription.value = '';
      taskPriority.value = 'medium';
      taskDueDate.value = '';
      selectedStepId.value = props.stepId;
    }
    showError.value = false;
  },
  { immediate: true }
);

// Watch for step changes
watch(
  () => props.stepId,
  newStepId => {
    if (!isEditing.value && newStepId) {
      selectedStepId.value = newStepId;
    }
  },
  { immediate: true }
);
</script>

<style scoped>
/* Custom scrollbar */
.overflow-y-auto::-webkit-scrollbar {
  width: 8px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: transparent;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: #cbd5e0;
  border-radius: 4px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: #a0aec0;
}

textarea::-webkit-scrollbar {
  width: 6px;
}

textarea::-webkit-scrollbar-track {
  background: transparent;
}

textarea::-webkit-scrollbar-thumb {
  background: #cbd5e0;
  border-radius: 3px;
}

textarea::-webkit-scrollbar-thumb:hover {
  background: #a0aec0;
}
</style>
