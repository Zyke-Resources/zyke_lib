import { ModalProvider } from "./context/ModalContext";
import PromptModule from "./modules/prompt";
import ClipboardModule from "./modules/clipboard";
import ModalModule from "./modules/modal";
import InputDialogModule from "./modules/input_dialog";

/**
 * App Shell
 *
 * Each UI feature lives in its own module under src/modules/
 */
const App = () => (
	<ModalProvider>
		<PromptModule />
		<ClipboardModule />
		<ModalModule />
		<InputDialogModule />
	</ModalProvider>
);

export default App;
