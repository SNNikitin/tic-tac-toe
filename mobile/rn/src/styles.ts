import { StyleSheet } from 'react-native';
import { colors } from './colors';

export const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
  },
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  stub: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 40,
  },
  stubTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  stubText: {
    fontSize: 16,
    color: colors.secondaryText,
    textAlign: 'center',
  },
  headerButtonGreen: {
    fontSize: 14,
    color: colors.success,
  },
  headerButtonBlue: {
    fontSize: 14,
    color: colors.accent,
  },
  content: {
    flex: 1,
    alignItems: 'center',
  },
  picker: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 16,
    paddingBottom: 32,
  },
  pickerLabel: {
    fontSize: 16,
    marginRight: 12,
  },
  pickerOptions: {
    flexDirection: 'row',
    gap: 8,
  },
  pickerOption: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: colors.accent,
    borderRadius: 6,
  },
  pickerOptionSelected: {
    backgroundColor: colors.accent,
  },
  pickerText: {
    color: colors.accent,
    fontSize: 14,
  },
  pickerTextSelected: {
    color: colors.white,
  },
  board: {
    backgroundColor: colors.grid,
    padding: 2,
  },
  boardRow: {
    flexDirection: 'row',
  },
  cell: {
    width: 100,
    height: 100,
    borderWidth: 1,
    borderColor: colors.grid,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.white,
  },
  cellWinning: {
    backgroundColor: colors.winningCell,
  },
  cellText: {
    fontSize: 50,
    fontWeight: 'bold',
  },
  cellX: {
    color: colors.accent,
  },
  cellO: {
    color: colors.danger,
  },
  overlay: {
    ...StyleSheet.absoluteFill,
    backgroundColor: colors.overlayLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  resultBadge: {
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 12,
  },
  resultText: {
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.white,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: colors.overlay,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalKeyboard: {
    width: '100%',
    alignItems: 'center',
  },
  modalContainer: {
    width: '85%',
    maxWidth: 320,
    backgroundColor: colors.white,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 16,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 24,
  },
  modalTitle: {
    flex: 1,
    fontSize: 17,
    fontWeight: '600',
    textAlign: 'center',
  },
  modalHeaderSpacer: {
    width: 50,
  },
  modalCancelText: {
    fontSize: 16,
    color: colors.accent,
    width: 50,
  },
  modalInput: {
    height: 44,
    borderWidth: 1,
    borderColor: colors.inputBorder,
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 16,
    backgroundColor: colors.white,
    marginBottom: 16,
  },
  modalSubmit: {
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: colors.accent,
    alignItems: 'center',
  },
  modalSubmitDisabled: {
    backgroundColor: colors.disabled,
  },
  modalSubmitText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.white,
  },
  backText: {
    color: colors.accent,
    fontSize: 14,
  },
  placeholder: {
    width: 40,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    marginTop: 8,
    fontSize: 16,
    color: colors.secondaryText,
  },
  empty: {
    fontSize: 16,
    color: colors.secondaryText,
  },
  list: {
    padding: 16,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  rank: {
    width: 40,
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.accent,
  },
  info: {
    flex: 1,
  },
  name: {
    fontSize: 18,
    fontWeight: '500',
  },
  stats: {
    fontSize: 14,
    color: colors.secondaryText,
    marginTop: 4,
  },
});
