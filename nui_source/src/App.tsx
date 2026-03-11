import PromptModule from "./modules/prompt";
import ClipboardModule from "./modules/clipboard";

/**
 * App Shell
 *
 * Each UI feature lives in its own module under src/modules/
 */
const App = () => (
	<>
		<PromptModule />
		<ClipboardModule />
	</>
);

export default App;
