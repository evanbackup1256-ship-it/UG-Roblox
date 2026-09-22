// ui/TextInput.tsx — Styled search input with clear button

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";

interface TextInputProps {
	placeholder?: string;
	value?: string;
	onChange: (text: string) => void;
	layoutOrder?: number;
}

export function TextInput({ placeholder = "Search…", onChange, layoutOrder }: TextInputProps) {
	const [focused, setFocused] = React.useState(false);
	const ref = React.createRef<TextBox>();

	return (
		<frame
			BackgroundColor3={C.recessed}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, 40)}
			LayoutOrder={layoutOrder}
		>
			<uicorner CornerRadius={new UDim(0, R.control)} />
			<uistroke
				Color={focused ? C.accent : C.hairline}
				Thickness={1}
				Transparency={focused ? 0.3 : 0.65}
			/>

			{/* Search icon */}
			<imagelabel
				key="SearchIco"
				Image="rbxassetid://7733765045"
				ImageColor3={focused ? C.accent : C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(0, 18, 0, 18)}
				Position={new UDim2(0, 10, 0.5, 0)}
				AnchorPoint={new Vector2(0, 0.5)}
				ScaleType={Enum.ScaleType.Fit}
			/>

			<textbox
				ref={ref}
				key="Input"
				PlaceholderText={placeholder}
				PlaceholderColor3={C.textMuted}
				Text=""
				Font={Font.body}
				TextSize={Size.body}
				TextColor3={C.textPrimary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -36, 1, 0)}
				Position={new UDim2(0, 32, 0, 0)}
				TextXAlignment={Enum.TextXAlignment.Left}
				ClearTextOnFocus={false}
				Event={{
					Focused: () => setFocused(true),
					FocusLost: () => setFocused(false),
				}}
				Change={{
					Text: (rbx) => onChange(rbx.Text),
				}}
			/>
		</frame>
	);
}

