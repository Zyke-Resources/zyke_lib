import { useState, useCallback, useRef } from "react";
import { listen, send } from "../../utils/Nui";
import { useModalContext } from "../../context/ModalContext";
import ContextMenu, { MODAL_ID, type ContextMenuData } from "./ContextMenu";

const ContextMenuModule = () => {
	const { openModal, closeModal } = useModalContext();
	const [data, setData] = useState<ContextMenuData | null>(null);
	const [navigatedData, setNavigatedData] = useState<ContextMenuData | null>(null);
	const cleanupTimer = useRef<number | null>(null);

	const clearCleanupTimer = useCallback(() => {
		if (cleanupTimer.current === null) return;

		window.clearTimeout(cleanupTimer.current);
		cleanupTimer.current = null;
	}, []);

	const cleanup = useCallback(() => {
		clearCleanupTimer();
		closeModal(MODAL_ID);
		cleanupTimer.current = window.setTimeout(() => {
			setData(null);
			setNavigatedData(null);
			cleanupTimer.current = null;
		}, 250);
	}, [clearCleanupTimer, closeModal]);

	listen("OpenContextMenu", (menuData: ContextMenuData) => {
		clearCleanupTimer();
		setData(menuData);
		setNavigatedData(null);

		const canClose = menuData.canClose !== false;
		const menuId = menuData.id || "";

		openModal(MODAL_ID, canClose, () => {
			send("close", { menuId }, "Context");
		});
	});

	listen("CloseContextMenu", () => {
		cleanup();
	});

	listen("NavigateContextMenu", (menuData: ContextMenuData) => {
		clearCleanupTimer();
		setNavigatedData(menuData);
	});

	const handleSelect = useCallback(
		(index: number, amount?: number) => {
			const activeData = navigatedData || data;
			if (!activeData) return;

			const option = activeData.options[index];
			if (!option) return;

			const menuId = activeData.id || "";

			send(
				"select",
				{
					menuId,
					optionIndex: index + 1,
					args: option.args,
					value: option.value,
					amount,
				},
				"Context"
			);
		},
		[data, navigatedData]
	);

	const handleConfirm = useCallback(
		(selected: any[]) => {
			const activeData = navigatedData || data;
			if (!activeData) return;

			const menuId = activeData.id || "";

			send("confirm", { menuId, selected }, "Context");
		},
		[data, navigatedData]
	);

	const handleHover = useCallback(
		(index: number | null) => {
			const activeData = navigatedData || data;
			if (!activeData) return;

			const menuId = activeData.id || "";
			if (index === null) {
				send("hoverEnd", { menuId }, "Context");
				return;
			}

			send(
				"hover",
				{
					menuId,
					optionIndex: index + 1,
				},
				"Context"
			);
		},
		[data, navigatedData]
	);

	const handleNavigate = useCallback(
		(target: string | any) => {
			const activeData = navigatedData || data;
			if (!activeData) return;

			const menuId = activeData.id || "";

			send(
				"navigate",
				{
					menuId,
					targetId: typeof target === "string" ? target : target,
				},
				"Context"
			);
		},
		[data, navigatedData]
	);

	const handleBack = useCallback(() => {
		const activeData = navigatedData || data;
		if (!activeData) return;

		const menuId = activeData.id || "";

		if (navigatedData && !navigatedData.menu) {
			setNavigatedData(null);
		}

		send("back", { menuId }, "Context");
	}, [data, navigatedData]);

	const handleClose = useCallback(() => {
		const activeData = navigatedData || data;
		if (!activeData) return;

		const menuId = activeData.id || "";

		send("close", { menuId }, "Context");
	}, [data, navigatedData]);

	return (
		<ContextMenu
			data={data}
			navigatedData={navigatedData}
			onSelect={handleSelect}
			onConfirm={handleConfirm}
			onNavigate={handleNavigate}
			onHover={handleHover}
			onBack={handleBack}
			onClose={handleClose}
		/>
	);
};

export default ContextMenuModule;
