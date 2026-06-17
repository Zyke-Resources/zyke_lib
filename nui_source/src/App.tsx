import { ModalProvider } from "./context/ModalContext";
import PromptModule from "./modules/prompt";
import ClipboardModule from "./modules/clipboard";
import ModalModule from "./modules/modal";
import InputDialogModule from "./modules/input_dialog";
import ContextMenuModule from "./modules/context_menu";
import ProgressModule from "./modules/progress";
import SkillCheckModule from "./modules/skill_check";

const App = () => (
	<ModalProvider>
		<PromptModule />
		<ClipboardModule />
		<ModalModule />
		<InputDialogModule />
		<ContextMenuModule />
		<ProgressModule />
		<SkillCheckModule />
	</ModalProvider>
);

export default App;
