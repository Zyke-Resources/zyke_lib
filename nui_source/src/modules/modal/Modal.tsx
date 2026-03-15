import { useDidUpdate } from "@mantine/hooks";
import { Box, LoadingOverlay, OptionalPortal } from "@mantine/core";
import CloseIcon from "@mui/icons-material/Close";
import {
    AnimatePresence,
    AnimationControls,
    motion,
    TargetAndTransition,
    VariantLabels,
} from "framer-motion";
import {
    ReactNode,
    useEffect,
    useRef,
    useState,
    type FC,
    type CSSProperties,
} from "react";
import { ButtonBase, CircularProgress } from "@mui/material";
import { useModalContext } from "../../context/ModalContext";

interface ModalProps {
    id: string;

    onClose?: () => void;
    onClickOutside?: () => void;
    disableClosing?: boolean; // Deprecated
    canClose?: boolean; // If you can close the menu, defaults to true
    disablePortal?: boolean;
    disableClickOutside?: boolean;
    disableBackdrop?: boolean;
    onBlockedCloseAttempt?: () => void;

    title?: string;
    icon?: ReactNode;
    description?: string;
    children?: ReactNode;
    closeButton?: boolean | (() => void);
    extraHeaderContent?: ReactNode;
    width?: string;
    loading?: boolean;
    loadingContent?: boolean;
    disableStyling?: boolean;
    disableHeader?: boolean;
    plain?: boolean;
    childrenContainerStyling?: CSSProperties;
    modalStyling?: any;
    headerStyling?: CSSProperties;
    modalAnimation?: {
        initial?: VariantLabels;
        animate?: AnimationControls;
        exit?: TargetAndTransition;
    };
    ignoreDefaultPositioning?: boolean;
}

const Modal: FC<ModalProps> = ({
    id,

    onClose,
    onClickOutside,
    disableClosing, // Deprecated
    canClose = true,
    disablePortal,
    disableClickOutside,
    disableBackdrop, // Does not disable clicking outside, just the styling of the backdrop
    onBlockedCloseAttempt, // If an attempt at closing the modal fails, this will be called

    title,
    icon,
    description,
    children,
    closeButton,
    extraHeaderContent,

    width,
    loading,
    loadingContent,
    disableStyling,
    disableHeader,
    plain,
    childrenContainerStyling,
    modalStyling,
    headerStyling,
    modalAnimation,
    ignoreDefaultPositioning,
}) => {
    // Backwards support
    if (disableClosing) canClose = false;

    const { modalsOpen, setModalDataProperty } = useModalContext();
    const [open, setOpen] = useState(false);
    const [suspended, setSuspended] = useState<boolean>(false);
    const idx = useRef(0);
    const wasSuspended = useRef(false);

    useEffect(() => {
        if (modalsOpen[id] && !open) {
            setOpen(true);
            idx.current = (modalsOpen[id]?.idx || 0) + 1000;
        } else if (!modalsOpen[id] && open) {
            setOpen(false);
            if (onClose) onClose();
        }

        if (modalsOpen[id]) {
            if (modalsOpen[id].suspended && !suspended) {
                setSuspended(true);
                wasSuspended.current = true;
            } else if (!modalsOpen[id].suspended && suspended) {
                setSuspended(false);
            }
        }
    }, [modalsOpen[id]]);

    if (plain) {
        disableHeader = true;
        closeButton = false;
    }

    const animDelay =
        wasSuspended.current === true
            ? 0.0
            : loading !== undefined && modalsOpen[id] !== undefined
                ? 0.0
                : 0;

    // In order to properly act on the value, we change it here
    // We do set it to true instantly when we set the suspended useEffect to keep it accurate
    useEffect(() => {
        wasSuspended.current = suspended;
    }, [suspended]);

    useDidUpdate(() => {
        setModalDataProperty(id, "canClose", canClose);
        setModalDataProperty(id, "onBlockedCloseAttempt", onBlockedCloseAttempt);
    }, [canClose, onBlockedCloseAttempt])

    return (
        <OptionalPortal
            withinPortal={!disablePortal}
            className="modal"
            id={`modal-${id}`}
            style={{
                opacity: modalStyling?.opacity,
                transition: modalStyling?.transition,
            }}
        >
            <BackDrop
                id={id}
                open={open && !suspended}
                disableBackdrop={disableBackdrop}
                disableClickOutside={disableClickOutside}
                canClose={canClose}
                onClickOutside={onClickOutside}
                idx={idx.current - 1}
                onBlockedCloseAttempt={onBlockedCloseAttempt}
            />
            <Loading
                open={open}
                loading={loading ? true : false}
                zIndex={idx.current}
            />
            <AnimatePresence>
                {open && !loading && (
                    <motion.div
                        className="modal-content"
                        id={`modal-content-${id}`}
                        initial={
                            modalAnimation?.initial || {
                                opacity: 0,
                                scale: 0.98,
                            }
                        }
                        animate={
                            modalAnimation?.animate || {
                                opacity: suspended ? 0.0 : 1.0,
                                scale: 1.0,
                            }
                        }
                        exit={
                            modalAnimation?.exit || {
                                opacity: 0,
                                scale: 0.98,
                            }
                        }
                        transition={{
                            duration: 0.2,
                            delay: animDelay,
                        }}
                        style={{
                            position: "absolute",
                            top: !ignoreDefaultPositioning ? "50%" : undefined,
                            left: !ignoreDefaultPositioning ? "50%" : undefined,
                            translateX: !ignoreDefaultPositioning
                                ? "-50%"
                                : undefined,
                            translateY: !ignoreDefaultPositioning
                                ? "-50%"
                                : undefined,
                            background: "rgba(var(--dark))",
                            minWidth: !disablePortal ? "40rem" : undefined,
                            maxWidth: !disablePortal ? "80%" : undefined,
                            width: width,
                            zIndex: idx.current,
                            pointerEvents: suspended ? "none" : "auto",

                            borderRadius: !disableStyling
                                ? "var(--lborderRadius)"
                                : undefined,
                            boxShadow: !disableStyling
                                ? "0 0 5px 0 rgba(0, 0, 0, 0.5)"
                                : undefined,
                            boxSizing: "border-box",
                            border: !disableStyling
                                ? !disableHeader
                                    ? "1px solid rgba(var(--grey3))"
                                    : "1px solid rgba(var(--dark3))"
                                : "none",

                            ...modalStyling,
                        }}
                    >
                        <div
                            style={{
                                width: "100%",
                                height: "100%",
                                position: "relative",
                            }}
                        >
                            <Header
                                id={id}
                                disableStyling={disableStyling}
                                disableHeader={disableHeader}
                                headerStyling={headerStyling}
                                icon={icon}
                                title={title}
                                extraHeaderContent={extraHeaderContent}
                                closeButton={closeButton}
                                canClose={canClose}
                                onBlockedCloseAttempt={onBlockedCloseAttempt}
                                plain={plain}
                            />
                            {description && (
                                <Description description={description} />
                            )}
                            <ChildContainer
                                disableStyling={disableStyling}
                                disableHeader={disableHeader}
                                childrenContainerStyling={
                                    childrenContainerStyling
                                }
                                children={children}
                                loadingContent={loadingContent}
                            />
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </OptionalPortal>
    );
};

export default Modal;

interface HeaderProps {
    id?: string;
    disableStyling?: boolean;
    disableHeader?: boolean;
    headerStyling?: CSSProperties;
    icon?: ReactNode;
    title?: string;
    extraHeaderContent?: ReactNode;
    closeButton?: boolean | (() => void);
    canClose?: boolean;
    onBlockedCloseAttempt?: () => void;
    plain?: boolean;
}

const Header: FC<HeaderProps> = ({
    id,
    disableStyling,
    disableHeader,
    headerStyling,
    icon,
    title,
    extraHeaderContent,
    closeButton,
    canClose,
    plain,
    onBlockedCloseAttempt,
}) => {
    const { closeModal } = useModalContext();

    return (
        <div
            className="header-container"
            style={{
                width: "100%",
                boxSizing: "border-box",
                position: "relative",
                padding: !disableStyling
                    ? !disableHeader
                        ? "0.25rem 0.75rem"
                        : "0.5rem 1rem 0rem 1rem"
                    : "0",
                height: plain ? "0" : !disableStyling ? "3.5rem" : undefined,
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",

                background: !disableHeader ? "rgba(var(--grey))" : undefined,
                boxShadow: !disableHeader
                    ? "0 2px 3px 0 rgba(0, 0, 0, 0.2)"
                    : undefined,
                borderBottom: !disableHeader
                    ? "1px solid rgba(var(--grey3))"
                    : undefined,

                ...headerStyling,
            }}
        >
            <Box
                className="title-container"
                sx={{
                    width: "100%",
                    overflow: "hidden",
                    display: "flex",
                    justifyContent: "start",
                    alignItems: "center",

                    "& svg": {
                        marginRight: "0.5rem",
                        fill: "rgba(var(--icon))",
                        fontSize: !disableHeader ? "1.9rem" : "1.6rem",
                    },

                    "& .material-icons, & .material-icons-outlined": {
                        marginRight: "0.5rem",
                        color: "rgba(var(--icon))",
                        fontSize: !disableHeader ? "1.9rem !important" : "1.6rem !important",
                        width: !disableHeader ? "1.9rem" : "1.6rem",
                        height: !disableHeader ? "1.9rem" : "1.6rem",
                    },
                }}
            >
                {icon && icon}
                {title && (
                    <h1
                        className="truncate"
                        style={{
                            margin: "0.2rem 0 0 0",
                            fontSize: !disableHeader ? "2rem" : "1.7rem",
                        }}
                    >
                        {title}
                    </h1>
                )}
            </Box>

            {extraHeaderContent && extraHeaderContent}
            {closeButton && (
                <div
                    className="close-button-container"
                    style={{
                        width: "3rem",
                        height: "100%",
                        display: "flex",
                        justifyContent: "end",
                        alignItems: "center",
                    }}
                >
                    <ButtonBase
                        sx={{
                            borderRadius: "50%",
                        }}
                    >
                        <div
                            style={{
                                display: "flex",
                                justifyContent: "center",
                                alignItems: "center",
                                padding: "0.2rem",

                                cursor: "pointer",
                                transition: "background 0.2s",
                            }}
                            onClick={() => {
                                if (!canClose) {
                                    if (onBlockedCloseAttempt)
                                        onBlockedCloseAttempt();
                                    return;
                                }
                                if (typeof closeButton === "function")
                                    return closeButton();

                                closeModal(id);
                            }}
                        >
                            <CloseIcon
                                sx={{
                                    color: "rgba(var(--icon))",
                                    width: "1.65rem",
                                    height: "1.65rem",
                                }}
                            />
                        </div>
                    </ButtonBase>
                </div>
            )}
        </div>
    );
};

const Description = ({ description }: { description: string }) => {
    return (
        <>
            {description ? (
                <div
                    className="description-container"
                    style={{
                        padding: "0 1rem 0.5rem 1rem",
                        marginRight: "3rem",
                    }}
                >
                    <p
                        style={{
                            color: "rgba(var(--secText))",
                            fontSize: "1.2rem",
                        }}
                    >
                        {description}
                    </p>
                </div>
            ) : null}
        </>
    );
};

interface BackDropProps {
    open: boolean;
    disableBackdrop?: boolean;
    disableClickOutside?: boolean;
    canClose?: boolean;
    onClickOutside?: () => void;
    onBlockedCloseAttempt?: () => void;
    id?: string;
    idx: number;
}

const BackDrop: FC<BackDropProps> = ({
    open,
    disableBackdrop,
    disableClickOutside,
    canClose,
    onClickOutside,
    onBlockedCloseAttempt,
    id,
    idx,
}) => {
    const { closeModal } = useModalContext();

    return (
        <AnimatePresence>
            {open && (
                <motion.div
                    style={{
                        position: "absolute",
                        width: "100%",
                        height: "100%",
                        background: `rgba(0, 0, 0, ${disableBackdrop ? "0" : "0.5"
                            })`,
                        top: 0,
                        left: 0,
                        zIndex: idx,
                    }}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    onClick={() => {
                        if (disableClickOutside) return;
                        if (!canClose) {
                            if (onBlockedCloseAttempt)
                                onBlockedCloseAttempt();
                            return;
                        }

                        if (onClickOutside) onClickOutside();

                        closeModal(id);
                    }}
                ></motion.div>
            )}
        </AnimatePresence>
    );
};

const Loading = ({
    open,
    loading,
    zIndex,
}: {
    open: boolean;
    loading: boolean;
    zIndex: number;
}) => {
    return (
        <AnimatePresence>
            {open && loading && (
                <motion.div
                    initial={{ opacity: 0, scale: 1 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 1 }}
                    transition={{ duration: 0.2 }}
                    style={{
                        position: "absolute",
                        top: "50%",
                        left: "50%",
                        translateX: "-50%",
                        translateY: "-50%",
                        zIndex: zIndex,
                    }}
                >
                    <CircularProgress />
                </motion.div>
            )}
        </AnimatePresence>
    );
};

interface ChildContainerProps {
    disableStyling?: boolean;
    disableHeader?: boolean;
    childrenContainerStyling?: CSSProperties;
    children: ReactNode;
    loadingContent?: boolean;
}

const ChildContainer: FC<ChildContainerProps> = ({
    disableStyling,
    disableHeader,
    childrenContainerStyling,
    children,
    loadingContent = false,
}) => {
    return (
        <div style={{ position: "relative", height: "100%" }}>
            <div
                className="children-container"
                style={{
                    height: "100%",
                    padding: !disableStyling
                        ? !disableHeader
                            ? "1rem"
                            : "0rem 1rem 1rem 1rem"
                        : "0",
                    ...childrenContainerStyling,
                }}
            >
                {children}
            </div>

            <LoadingOverlay visible={loadingContent} zIndex={1000} />
        </div>
    );
};
