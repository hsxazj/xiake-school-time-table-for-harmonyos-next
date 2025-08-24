export interface PickerItem {
  id: number;
  name: string;
}

export interface PickerProps {
  items: PickerItem[];
  selectedIndex: number;
  title: string;
  onConfirm?: (item: PickerItem, index: number) => void;
  onCancel?: () => void;
}