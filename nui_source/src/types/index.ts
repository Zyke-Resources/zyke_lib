// Prompt
export interface PromptData {
    id: string;
    key: string;
    label: string;
}

// Modal
export interface OpenedModal {
    canClose: boolean;
    onClose: (() => void) | null;
    suspended: boolean;
    idx: number;
    onBlockedCloseAttempt: (() => void) | null;
}
