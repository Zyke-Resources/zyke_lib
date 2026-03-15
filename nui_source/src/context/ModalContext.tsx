import React, {
	createContext,
	ReactNode,
	useContext,
	useEffect,
	useRef,
	useState,
} from "react";
import { OpenedModal } from "../types";

interface ModalContextType {
	modalsOpen: { [key: string]: OpenedModal };
	modalQueue: string[];
	isModalOpen: (name: string) => boolean;
	openModal: (name: string, canClose?: boolean, onClose?: () => void) => void;
	closeModal: (name?: string) => void;
	hasModalsOpen: () => boolean;
	setModalDataProperty: (modalId: string, property: keyof OpenedModal, value: any) => void;
	suspendModals: () => void;
	unsuspendModals: () => void;
}

const ModalContext = createContext<ModalContextType | undefined>(undefined);

export const useModalContext = (): ModalContextType => {
	const context = useContext(ModalContext);
	if (!context) {
		throw new Error("useModalContext must be used within a ModalProvider");
	}

	return context;
};

export const ModalProvider: React.FC<{ children: ReactNode }> = ({
	children,
}) => {
	const modalIdx = useRef(0);

	const [modalsOpen, setModalsOpen] = useState<{
		[key: string]: OpenedModal;
	}>({});
	const [modalQueue, setModalQueue] = useState<string[]>([]);

	const isModalOpen = (name: string) => {
		return modalsOpen[name] !== undefined;
	};

	const openModal = (
		name: string,
		canClose?: boolean,
		onClose?: () => void,
		onBlockedCloseAttempt?: () => void
	) => {
		modalIdx.current = modalIdx.current + 1;
		setModalsOpen((prev) => ({
			...prev,
			[name]: {
				canClose: canClose || true,
				onClose: onClose !== undefined ? onClose : null,
				suspended: false,
				idx: modalIdx.current,
				onBlockedCloseAttempt: onBlockedCloseAttempt !== undefined ? onBlockedCloseAttempt : null,
			},
		}));
		setModalQueue((prev) => [...prev, name]);
	};

	// If no name is provided, close the last opened modal
	/**
	 * Closest the modal with the provided id, or the last opened modal if no id is provided
	 * If the target modal can not be closed, it will just return
	 * @param id? string
	 */
	const closeModal = (id?: string) => {
		if (!id) {
			id = modalQueue[modalQueue.length - 1];
		}

		if (!id) return;

		const modal = modalsOpen[id];
		if (!modal) return;
		if (!modal.canClose) {
			if (modal.onBlockedCloseAttempt) modal.onBlockedCloseAttempt();
			return;
		}

		if (modal.onClose) modal.onClose();

		setModalsOpen((prev) => {
			const { [id]: _, ...rest } = prev;
			return rest;
		});

		setModalQueue((prev) => prev.filter((modal) => modal !== id));
	};

	const setModalDataProperty = (modalId: string, property: keyof OpenedModal, value: any) => {
		const modal = modalsOpen[modalId];
		if (!modal) return;

		setModalsOpen((prev) => ({
			...prev,
			[modalId]: {
				...prev[modalId],
				[property]: value,
			},
		}));
	};

	const hasModalsOpen = () => {
		return modalQueue.length > 0;
	};

	const suspendModals = () => {
		// Blur active element to dismiss any hover/focus-based tooltips
		if (document.activeElement instanceof HTMLElement) {
			document.activeElement.blur();
		}

		// Hide any lingering tooltip portals
		document.body.classList.add("modals-suspended");

		const newModals: { [key: string]: OpenedModal } = {};

		for (const modalId in modalsOpen) {
			newModals[modalId] = {
				...modalsOpen[modalId],
				suspended: true,
			};
		}

		setModalsOpen(newModals);
	};

	const unsuspendModals = () => {
		document.body.classList.remove("modals-suspended");

		const newModals: { [key: string]: OpenedModal } = {};

		for (const modalId in modalsOpen) {
			newModals[modalId] = {
				...modalsOpen[modalId],
				suspended: false,
			};
		}

		setModalsOpen(newModals);
	};

	useEffect(() => {
		const onKeyDown = (e: KeyboardEvent) => {
			if (e.key === "Escape") {
				closeModal();
			}
		};

		window.addEventListener("keydown", onKeyDown);

		return () => {
			window.removeEventListener("keydown", onKeyDown);
		};
	}, [modalsOpen]);

	return (
		<ModalContext.Provider
			value={{
				modalsOpen,
				modalQueue,
				isModalOpen,
				openModal,
				closeModal,
				hasModalsOpen,
				setModalDataProperty,
				suspendModals,
				unsuspendModals,
			}}
		>
			{children}
		</ModalContext.Provider>
	);
};
