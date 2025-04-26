package ${PACKAGE_NAME}

import androidx.fragment.app.viewModels
import ${applicationId}.R
import ${applicationId}.BR
import ${applicationId}.databinding.DialogFragment${NAME}Binding
import com.studio.common.ui.base.BaseBindingDialogFragment
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ${NAME}DialogFragment : BaseBindingDialogFragment<${NAME}ViewModel, DialogFragment${NAME}Binding>() {
    override val viewModel by viewModels<${NAME}ViewModel>()

    override fun getLayoutId(): Int = R.layout.dialog_fragment_${lower_name}

    override fun getViewModelBindingVariable(): Int = BR.viewModel

    override fun initView() {
        Unit
    }

    override fun initViewModel() {
        Unit
    }
}