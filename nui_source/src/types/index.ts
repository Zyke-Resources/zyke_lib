// Prompt
export interface PromptData {
    id: string;
    resource: string;
    key: string;
    label: string;
}

export interface RemovePromptData {
    id?: string;
    resource: string;
}

// Modal
export interface OpenedModal {
    canClose: boolean;
    onClose: (() => void) | null;
    suspended: boolean;
    idx: number;
    onBlockedCloseAttempt: (() => void) | null;
}
