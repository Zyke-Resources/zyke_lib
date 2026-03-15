/**
 * Icon Registry
 *
 * Maps string names to React icon components from MUI and react-icons.
 * This lets Lua code reference icons by name (e.g. "confirm", "person")
 * and have them resolved to the actual SVG component on the NUI side.
 *
 * Material Icons (font-based) are handled separately by MaterialIcon.tsx.
 * This registry is for specific SVG icons from external libraries.
 */

import React from "react";

// MUI Icons
import PersonIcon from "@mui/icons-material/Person";
import GarageIcon from "@mui/icons-material/Garage";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import CloseIcon from "@mui/icons-material/Close";
import AddIcon from "@mui/icons-material/Add";
import SearchIcon from "@mui/icons-material/Search";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import SaveIcon from "@mui/icons-material/Save";
import SettingsIcon from "@mui/icons-material/Settings";
import LabelIcon from "@mui/icons-material/Label";
import BuildIcon from "@mui/icons-material/Build";
import KeyboardIcon from "@mui/icons-material/Keyboard";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import RefreshIcon from "@mui/icons-material/Refresh";
import WarehouseIcon from "@mui/icons-material/Warehouse";
import CommuteIcon from "@mui/icons-material/Commute";
import WorkIcon from "@mui/icons-material/Work";
import GavelIcon from "@mui/icons-material/Gavel";
import ManageAccountsIcon from "@mui/icons-material/ManageAccounts";
import ConstructionIcon from "@mui/icons-material/Construction";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import RestoreIcon from "@mui/icons-material/Restore";
import PropaneIcon from "@mui/icons-material/Propane";
import DirectionsCarIcon from "@mui/icons-material/DirectionsCar";
import ColorLensIcon from "@mui/icons-material/ColorLens";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CheckIcon from "@mui/icons-material/Check";
import InfoIcon from "@mui/icons-material/Info";
import WarningIcon from "@mui/icons-material/Warning";
import ErrorIcon from "@mui/icons-material/Error";
import HelpIcon from "@mui/icons-material/Help";
import LockIcon from "@mui/icons-material/Lock";
import LockOpenIcon from "@mui/icons-material/LockOpen";
import VpnKeyIcon from "@mui/icons-material/VpnKey";
import MoneyIcon from "@mui/icons-material/AttachMoney";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";

// react-icons
import { SiAuthy, SiGitbook } from "react-icons/si";
import { ImInfo } from "react-icons/im";
import { PiEngineFill } from "react-icons/pi";
import { GiJerrycan, GiCarWheel, GiSpring } from "react-icons/gi";
import { TbManualGearbox } from "react-icons/tb";
import { FaBolt, FaKey, FaCar, FaWrench, FaGasPump } from "react-icons/fa";

/**
 * Registry mapping string names to icon components.
 * Names should be lowercase, descriptive, and easy to remember from Lua.
 */
const iconRegistry: Record<string, React.ReactNode> = {
	// ── Confirm / Action ───────────────────────────
	confirm: <SiAuthy />,
	check: <CheckIcon />,
	save: <SaveIcon />,
	edit: <EditIcon />,
	delete: <DeleteIcon />,
	add: <AddIcon />,
	close: <CloseIcon />,
	refresh: <RefreshIcon />,
	restore: <RestoreIcon />,
	copy: <ContentCopyIcon />,
	search: <SearchIcon />,
	back: <ArrowBackIcon />,

	// ── People / Accounts ──────────────────────────
	person: <PersonIcon />,
	accounts: <ManageAccountsIcon />,

	// ── Vehicles / Garages ─────────────────────────
	garage: <GarageIcon />,
	warehouse: <WarehouseIcon />,
	car: <DirectionsCarIcon />,
	commute: <CommuteIcon />,
	engine: <PiEngineFill />,
	fuel: <GiJerrycan />,
	gas: <FaGasPump />,
	wheel: <GiCarWheel />,
	suspension: <GiSpring />,
	transmission: <TbManualGearbox />,
	turbo: <FaBolt />,
	propane: <PropaneIcon />,

	// ── Labels / Info ──────────────────────────────
	receipt: <ReceiptLongIcon />,
	label: <LabelIcon />,
	info: <InfoIcon />,
	info_alt: <ImInfo />,
	warning: <WarningIcon />,
	error: <ErrorIcon />,
	help: <HelpIcon />,
	gitbook: <SiGitbook />,

	// ── Keys / Security ────────────────────────────
	key: <VpnKeyIcon />,
	key_alt: <FaKey />,
	lock: <LockIcon />,
	unlock: <LockOpenIcon />,

	// ── Work / Settings ────────────────────────────
	settings: <SettingsIcon />,
	build: <BuildIcon />,
	construction: <ConstructionIcon />,
	wrench: <FaWrench />,
	work: <WorkIcon />,
	gavel: <GavelIcon />,
	keyboard: <KeyboardIcon />,
	location: <LocationOnIcon />,
	time: <AccessTimeIcon />,
	color: <ColorLensIcon />,

	// ── Commerce ───────────────────────────────────
	money: <MoneyIcon />,
	cart: <ShoppingCartIcon />,
	car_alt: <FaCar />,
};

export default iconRegistry;
