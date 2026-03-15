import ReactDOM from "react-dom/client";
import App from "./App";

import "./styling/index.css"
import "./styling/base_defaults.css"
import "./styling/kbd.css"
import "./styling/inputs.css"
import "./styling/select.css"
import "./styling/checkbox.css"
import "./styling/slider.css"

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(<App />);
