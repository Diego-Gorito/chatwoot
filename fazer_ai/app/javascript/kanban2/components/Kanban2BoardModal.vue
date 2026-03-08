<script setup>
import { ref, watch, onMounted, computed, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  board: {
    type: Object,
    default: null,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'save']);

const dialogId = `kanban2-board-modal-${Math.random().toString(36).substr(2, 9)}`;

const { t } = useI18n();

const name = ref('');
const description = ref('');
const dialogRef = ref(null);
const discardDialogRef = ref(null);
const showDiscardDialog = ref(false);
const isDiscarding = ref(false);
const discardAction = ref('close'); // 'close' or 'back'
const initialValues = ref({});

const isEditing = computed(() => !!props.board && !!props.board.id);

const modalTitle = computed(() => {
  if (isEditing.value) {
    return t('KANBAN.BOARD_MODAL.EDIT_TITLE', 'Edit Board');
  }
  return t('KANBAN.BOARD_MODAL.CREATE_TITLE', 'Create Board');
});

const openModal = () => {
  dialogRef.value?.open();
  if (isEditing.value) {
    initialValues.value = {
      name: props.board.name,
      description: props.board.description || '',
    };
    name.value = initialValues.value.name;
    description.value = initialValues.value.description;
  } else {
    initialValues.value = {
      name: '',
      description: '',
    };
    name.value = '';
    description.value = '';
  }
};

const onSave = () => {
  if (!name.value) return;

  const payload = {
    name: name.value,
    description: description.value,
  };

  if (isEditing.value) {
    payload.id = props.board.id;
  }

  emit('save', payload);
};

const hasChanges = computed(() => {
  return (
    name.value !== initialValues.value.name ||
    description.value !== initialValues.value.description
  );
});

const shouldIgnoreClickOutside = computed(() => {
  return props.isSaving || showDiscardDialog.value || hasChanges.value;
});

onMounted(() => {
  if (props.show) {
    openModal();
  }
});

watch(
  () => props.show,
  val => {
    if (val) {
      openModal();
    } else {
      dialogRef.value?.close();
      showDiscardDialog.value = false;
    }
  }
);

const handleClose = () => {
  if (props.isSaving || isDiscarding.value) {
    return;
  }

  if (hasChanges.value && !showDiscardDialog.value) {
    discardAction.value = 'close';
    showDiscardDialog.value = true;
  } else if (!hasChanges.value) {
    emit('close');
  }
};

const confirmDiscard = async () => {
  isDiscarding.value = true;
  showDiscardDialog.value = false;
  await nextTick();
  emit('close');

  setTimeout(() => {
    isDiscarding.value = false;
  }, 100);
};

const closeDiscardDialog = () => {
  showDiscardDialog.value = false;
};

watch(showDiscardDialog, async val => {
  if (val) {
    await nextTick();
    discardDialogRef.value?.open();
  }
});

const handleClickOutside = () => {
  if (props.isSaving || !props.show) return;

  if (hasChanges.value && !showDiscardDialog.value) {
    showDiscardDialog.value = true;
  }
};
</script>

<template>
  <Dialog
    :id="dialogId"
    ref="dialogRef"
    :title="modalTitle"
    width="3xl"
    overflow-y-auto
    :ignore-click-outside="shouldIgnoreClickOutside"
    @close="handleClose"
    @click-outside="handleClickOutside"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-2 text-sm font-medium text-n-slate-12">
        {{ t('KANBAN.BOARD_MODAL.NAME_LABEL', 'Board Name') }}
        <Input
          v-model="name"
          :placeholder="t('KANBAN.BOARD_MODAL.NAME_PLACEHOLDER', 'My Awesome Board')"
          required
          autocomplete="off"
          data-lpignore="true"
          data-1p-ignore="true"
          maxlength="60"
        />
      </label>

      <Editor
        v-model="description"
        :label="t('KANBAN.BOARD_MODAL.DESCRIPTION_LABEL', 'Description')"
        :placeholder="t('KANBAN.BOARD_MODAL.DESCRIPTION_PLACEHOLDER', 'Describe your board...')"
        class="w-full"
        :max-length="120"
      />
    </div>

    <template #footer>
      <div class="flex justify-between items-center w-full">
        <div></div>
        <div class="flex gap-2">
          <Button variant="ghost" color="slate" @click="handleClose">
            {{ t('KANBAN.BOARD_MODAL.CANCEL', 'Cancel') }}
          </Button>
          <Button
            :is-loading="isSaving"
            :disabled="!name"
            @click="onSave"
          >
            {{
              isEditing
                ? t('KANBAN.BOARD_MODAL.UPDATE', 'Update')
                : t('KANBAN.BOARD_MODAL.CREATE', 'Create')
            }}
          </Button>
        </div>
      </div>
    </template>
  </Dialog>

  <Dialog
    v-if="showDiscardDialog"
    ref="discardDialogRef"
    type="alert"
    :title="t('KANBAN.MODAL.DISCARD_TITLE', 'Discard changes?')"
    :description="t('KANBAN.MODAL.DISCARD_CONFIRMATION', 'You have unsaved changes. Are you sure you want to discard them?')"
    :confirm-button-label="t('KANBAN.MODAL.DISCARD', 'Discard')"
    @confirm="confirmDiscard"
    @close="closeDiscardDialog"
  />
</template>
