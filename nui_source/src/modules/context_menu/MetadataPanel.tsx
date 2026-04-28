import { FC } from "react";

interface ContextMetadata {
	label: string;
	value: any;
	progress?: number;
	colorScheme?: string;
}

interface MetadataPanelProps {
	title?: string;
	image?: string;
	metadata?: ContextMetadata[];
	visible: boolean;
}

const MetadataPanel: FC<MetadataPanelProps> = ({
	title,
	image,
	metadata,
	visible,
}) => {
	if (!visible) return null;

	return (
		<div
			style={{
				minWidth: "18rem",
				maxWidth: "22rem",
				background: "rgba(var(--dark2))",
				borderLeft: "1px solid rgba(var(--grey3))",
				padding: "1rem",
				display: "flex",
				flexDirection: "column",
				gap: "0.6rem",
				overflowY: "auto",
			}}
		>
			{title && (
				<p
					style={{
						margin: 0,
						fontSize: "1.5rem",
						fontWeight: 600,
						color: "rgb(var(--text))",
					}}
				>
					{title}
				</p>
			)}

			{image && (
				<div
					style={{
						width: "100%",
						display: "flex",
						justifyContent: "center",
						alignItems: "center",
						background: "rgba(var(--dark3))",
						borderRadius: "var(--mborderRadius)",
						padding: "0.8rem",
						boxSizing: "border-box",
						minHeight: "8rem",
					}}
				>
					<img
						src={image}
						alt=""
						style={{
							maxWidth: "100%",
							maxHeight: "16rem",
							objectFit: "contain",
							borderRadius: "var(--mborderRadius)",
						}}
					/>
				</div>
			)}

			{metadata?.map((entry, i) => (
				<div key={i} style={{ display: "flex", flexDirection: "column", gap: "0.15rem" }}>
					<p
						style={{
							fontSize: "1.1rem",
							color: "rgba(var(--secText))",
						}}
					>
						{entry.label}
					</p>
					<p
						style={{
							fontSize: "1.3rem",
							color: "rgb(var(--text))",
						}}
					>
						{String(entry.value)}
					</p>
					{entry.progress !== undefined && (
						<div
							style={{
								height: "3px",
								borderRadius: "2px",
								background: "rgba(var(--grey3))",
								overflow: "hidden",
								marginTop: "0.15rem",
							}}
						>
							<div
								style={{
									height: "100%",
									width: `${Math.min(100, Math.max(0, entry.progress))}%`,
									borderRadius: "2px",
									background: entry.colorScheme
										? `rgb(var(--${entry.colorScheme}, var(--blue1)))`
										: "rgb(var(--blue1))",
								}}
							/>
						</div>
					)}
				</div>
			))}
		</div>
	);
};

export default MetadataPanel;
